# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Assets
    module Behavior
      module Config
        extend Support::Extension

        apply_extension do
          configurable :assets do
            setting :types,
                    av: %w(.webm .snd .au .aiff .mp3 .mp2 .m2a .m3a .ogx .gg .oga .midi .mid .avi .wav .wave .mp4 .m4v .acc .m4a .flac),
                    data: %w(.json .xml .yml .yaml),
                    fonts: %w(.eot .otf .ttf .woff .woff2),
                    images: %w(.ico .bmp .gif .webp .png .jpg .jpeg .tiff .tif .svg),
                    scripts: %w(.js),
                    styles: %w(.css .sass .scss)

            setting :extensions do
              config.assets.types.values.flatten
            end

            setting :public, true
            setting :process, true
            setting :cache, false
            setting :minify, false
            setting :fingerprint, false
            setting :prefix, "/assets"
            setting :silent, true

            setting :public_path do
              File.join(config.root, "public")
            end

            setting :path do
              File.join(config.presenter.path, "assets")
            end

            setting :paths do
              @paths ||= [
                config.assets.path
              ]
            end

            setting :compile_path do
              config.assets.public_path
            end

            defaults :production do
              setting :minify, true
              setting :fingerprint, true
              setting :process, false
              setting :cache, true
              setting :silent, false
            end

            configurable :packs do
              setting :autoload, %i[pakyow]

              setting :path do
                File.join(config.assets.path, "packs")
              end

              setting :paths do
                @packs_paths ||= [
                  config.assets.packs.path,
                  config.assets.externals.path
                ]
              end
            end

            configurable :externals do
              setting :fetch, true
              setting :pakyow, true
              setting :provider, "https://unpkg.com/"
              setting :scripts, []

              setting :path do
                File.join(config.assets.packs.path, "vendor")
              end

              defaults :test do
                setting :fetch, false
              end

              defaults :production do
                setting :fetch, false
              end
            end
          end
        end
      end
    end
  end
end
