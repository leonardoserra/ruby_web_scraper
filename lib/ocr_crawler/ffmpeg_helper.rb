# frozen_string_literal: true

require 'shellwords'
require 'fileutils'

module OCRCrawler
  class FFmpegHelper
    def self.extract_frames(video_path, config)
      frames_dir = File.join(config[:output_dir], 'video_frames', File.basename(video_path, '.*'))
      FileUtils.mkdir_p(frames_dir)
      system(ffmpeg_command(video_path, frames_dir, config[:frame_rate]))
      frames_dir
    end

    def self.ffmpeg_command(video_path, frames_dir, fps)
      "ffmpeg -hide_banner -loglevel error -i \
      #{Shellwords.escape(video_path)} -vf fps=#{fps} \
      #{File.join(frames_dir, 'frame_%04d.jpg')}"
    end
  end
end
