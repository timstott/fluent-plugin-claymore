module Claymore
  # Provides method to extract asset symbole
  module AssetSymbol
    ASSET_REGEXP = /(?<asset>DRC|ETH|LBC|PASC|SC)(:| -)/

    def asset_symbol(line)
      match = line.match(ASSET_REGEXP)
      match && match[:asset]
    end
  end
end
