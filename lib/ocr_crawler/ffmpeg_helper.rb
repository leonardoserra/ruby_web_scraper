# frozen_string_literal: true

require 'shellwords'
require 'fileutils'

module OCRCrawler
  # OCRCrawler::FFmpegHelper
  # Small utility to construct and run ffmpeg commands to extract video frames.
  # All methods are class methods to be used as a stateless helper.
  class FFmpegHelper
    def self.extract_frames(video_path, config)
      frames_dir = File.join(config[:output_dir], 'video_frames', File.basename(video_path, '.*'))
      FileUtils.mkdir_p(frames_dir)
      cmd = ffmpeg_command(video_path, frames_dir, config[:frame_rate])
      success = system(cmd)
      success ? frames_dir : nil
    end

    def self.ffmpeg_command(video_path, frames_dir, fps)
      input = Shellwords.escape(video_path)
      output_pattern = Shellwords.escape(File.join(frames_dir, 'frame_%04d.jpg'))
      "ffmpeg -hide_banner -loglevel error -i #{input} -vf fps=#{fps} #{output_pattern}"
    end
  end
end
