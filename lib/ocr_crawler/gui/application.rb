# frozen_string_literal: true

require 'glimmer-dsl-libui'
require 'json'
require 'open3'

require_relative '../http_client'
require_relative '../site'
require_relative '../config'
require_relative '../crawler'
require_relative '../initializer'
require_relative '../downloader'
require_relative '../ffmpeg_helper'
require_relative '../ocr_executor'
require_relative '../result_recorder'
require_relative '../memory_manager'
require_relative 'config_serializer'

module OCRCrawler
  module GUI
    # Main GUI window for managing sites, global config, and running crawls.
    class Application
      include Glimmer

      attr_accessor :data, :output_text, :selected_site_index

      def initialize
        @data = ConfigSerializer.load
        @selected_site_index = -1
        @output_text = ''
        @running = false
      end

      def launch
        @window = window('OCR Crawler Config', 720, 560) do
          resizable true

          vertical_box do
            tab do
              tab_item('Sites') do
                vertical_box do
                  @sites_table = table do
                    text_column('URL')
                    text_column('Depth')
                    text_column('Media Selectors')
                    text_column('Link Selectors')

                    editable false

                    on_selection_changed do
                      @selected_site_index = @sites_table.selection
                    end
                  end

                  horizontal_box do
                    button('+ Add Site') do
                      on_clicked { open_site_form }
                    end
                    button('- Remove') do
                      on_clicked { remove_selected_site }
                    end
                    button('Edit') do
                      on_clicked { edit_selected_site }
                    end
                  end
                end
              end

              tab_item('Global Config') do
                vertical_box do
                  form do
                    entry do
                      label 'Threads'
                      @threads_entry = entry
                      @threads_entry.text = @data[:threads].to_s
                    end
                    entry do
                      label 'Output Directory'
                      @output_dir_entry = entry
                      @output_dir_entry.text = @data[:output_dir]
                    end
                    entry do
                      label 'Frame Rate'
                      @frame_rate_entry = entry
                      @frame_rate_entry.text = @data[:frame_rate].to_s
                    end
                    entry do
                      label 'GC Interval'
                      @gc_interval_entry = entry
                      @gc_interval_entry.text = @data[:gc_interval].to_s
                    end
                    entry do
                      label 'User Agent'
                      @user_agent_entry = entry
                      @user_agent_entry.text = @data[:user_agent]
                    end
                    @keep_files_checkbox = checkbox('Keep temporary files')
                    @keep_files_checkbox.checked = @data[:keep_files]
                  end
                end
              end
            end

            horizontal_box do
              button('Save Config') do
                on_clicked { save_config }
              end
              @run_button = button(@run_button_text = 'Run Crawler') do
                on_clicked { run_crawler }
              end
            end

            @output_log = non_wrapping_multiline_entry do
              read_only true
            end
          end
        end

        refresh_sites_table
        @window.show
      end

      private

      def refresh_sites_table
        rows = @data[:sites].map do |site|
          [
            site.url,
            site.max_depth.to_s,
            site.media_selectors.empty? ? '(default)' : site.media_selectors.join(', '),
            site.link_selectors == ['a[href]'] ? '(default)' : site.link_selectors.join(', ')
          ]
        end
        @sites_table.cell_rows = rows
        @selected_site_index = -1
      end

      def open_site_form(site = nil)
        edit_mode = !site.nil?
        form_data = if site
                      {
                        url: site.url,
                        max_depth: site.max_depth.to_s,
                        media_selectors: site.media_selectors.join("\n"),
                        link_selectors: site.link_selectors.join("\n")
                      }
                    else
                      {
                        url: '',
                        max_depth: '1',
                        media_selectors: '',
                        link_selectors: 'a[href]'
                      }
                    end

        dialog = window(edit_mode ? 'Edit Site' : 'Add Site', 500, 420) do
          resizable true

          vertical_box do
            label('URL')
            @form_url = entry
            @form_url.text = form_data[:url]

            label('Max Depth')
            @form_depth = entry
            @form_depth.text = form_data[:max_depth]

            group('Media CSS Selectors (one per line)') do
              @form_media = multiline_entry
              @form_media.text = form_data[:media_selectors]
            end

            group('Link CSS Selectors (one per line)') do
              @form_links = multiline_entry
              @form_links.text = form_data[:link_selectors]
            end

            horizontal_box do
              button('Cancel') do
                on_clicked { dialog.destroy }
              end
              button('Save') do
                on_clicked { save_site_form(dialog, edit_mode, form_data[:url]) }
              end
            end
          end
        end

        dialog.show
      end

      def edit_selected_site
        idx = @selected_site_index
        if idx.negative? || idx >= @data[:sites].size
          msg_box_error(@window, 'No Selection', 'Select a site from the table first.')
          return
        end
        open_site_form(@data[:sites][idx])
      end

      def remove_selected_site
        idx = @selected_site_index
        if idx.negative? || idx >= @data[:sites].size
          msg_box_error(@window, 'No Selection', 'Select a site from the table first.')
          return
        end
        @data[:sites].delete_at(idx)
        refresh_sites_table
      end

      def save_config
        @data[:threads] = @threads_entry.text.to_i
        @data[:output_dir] = @output_dir_entry.text.strip
        @data[:frame_rate] = @frame_rate_entry.text.to_i
        @data[:gc_interval] = @gc_interval_entry.text.to_i
        @data[:user_agent] = @user_agent_entry.text.strip
        @data[:keep_files] = @keep_files_checkbox.checked

        ConfigSerializer.save(@data)
        append_output("Config saved to config.json\n")
      end

      def run_crawler
        if @running
          append_output("Crawl already in progress.\n")
          return
        end

        save_config

        @running = true
        @run_button.enabled = false

        Thread.new do
          config = Config.load
          Initializer.setup
          crawler = Crawler.new(config)
          crawler.run

          post_process(config)
        rescue StandardError => e
          append_output("Error: #{e.message}\n#{e.backtrace.first(3).join("\n")}\n")
        ensure
          @running = false
          Glimmer::LibUI.queue_main { @run_button.enabled = true }
        end
      end

      def post_process(config)
        results_file = File.join(config[:output_dir], 'results.json')
        return append_output("No results.json found; nothing to post-process.\n") unless File.exist?(results_file)

        cfg = config
        discovered = JSON.parse(File.read(results_file))
        processed = []

        discovered.each do |entry|
          type = entry['type'].to_s
          page = entry['source_page']
          src = entry['url']
          next unless src

          case type
          when 'media', 'image', 'img'
            local = Downloader.download(src, 'images', cfg)
            text = ''
            text = OCRExecutor.perform(local) if local && File.exist?(local)
            processed << ResultRecorder.build(page, 'media', src, local, text)
            append_output("  OCR: #{src} -> #{text[0..80]}\n")
          when 'video'
            local = Downloader.download(src, 'videos', cfg)
            if local && File.exist?(local)
              frames_dir = FFmpegHelper.extract_frames(local, cfg)
              OCRExecutor.batch_from_frames(frames_dir, page, src, processed) if frames_dir
            end
            processed << ResultRecorder.build(page, 'video', src, local, '')
          end
          MemoryManager.cleanup_file(local) unless cfg[:keep_files] || local.nil?
        end

        FileUtils.mkdir_p(cfg[:output_dir])
        out_file = File.join(cfg[:output_dir], 'processed_results.json')
        File.write(out_file, JSON.pretty_generate(processed))
        append_output("Processed results written to #{out_file}\n")
      end

      def save_site_form(dialog, edit_mode, original_url)
        url = @form_url.text.strip
        if url.empty?
          msg_box_error(dialog, 'Validation Error', 'URL cannot be empty.')
          return
        end

        site_obj = Site.new(
          url: url,
          max_depth: @form_depth.text.strip.to_i,
          media_selectors: @form_media.text.strip.lines.map(&:strip).reject(&:empty?),
          link_selectors: @form_links.text.strip.lines.map(&:strip).reject(&:empty?)
        )

        if edit_mode
          idx = @data[:sites].index { |s| s.url == original_url }
          @data[:sites][idx] = site_obj if idx
        else
          @data[:sites] << site_obj
        end

        refresh_sites_table
        dialog.destroy
      end

      def append_output(text)
        @output_text += text
        Glimmer::LibUI.queue_main do
          @output_log.text = @output_text
        end
      end
    end
  end
end
