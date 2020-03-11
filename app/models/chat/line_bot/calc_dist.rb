module Chat::LineBot::CalcDist
  # 定数 ( GRS80 ( 世界測地系 ) )
  GRS80_R_X   = 6378137.000000 # 赤道半径
  GRS80_R_Y   = 6356752.314140 # 極半径

  class Calc
    def initialize(lat1, lon1, lat2, lon2)
      @lat1 = lat1
      @lon1 = lon1
      @lat2 = lat2
      @lon2 = lon2
    end

    # 距離計算
    def calc_dist
      # 指定測地系の赤道半径・極半径を設定
      r_x = GRS80_R_X
      r_y = GRS80_R_Y

      # 2点の経度の差を計算 ( ラジアン )
      a_x = @lon1 * Math::PI / 180.0 - @lon2 * Math::PI / 180.0

      # 2点の緯度の差を計算 ( ラジアン )
      a_y = @lat1 * Math::PI / 180.0 - @lat2 * Math::PI / 180.0

      # 2点の緯度の平均を計算
      p = ( @lat1 * Math::PI / 180.0 + @lat2 * Math::PI / 180.0 ) / 2.0

      # 離心率を計算
      e = Math::sqrt( ( r_x ** 2 - r_y ** 2 ) / ( r_x ** 2 ).to_f )

      # 子午線・卯酉線曲率半径の分母Wを計算
      w = Math::sqrt( 1 - ( e ** 2 ) * ( Math::sin( p ) ** 2 ) )

      # 子午線曲率半径を計算
      m = r_x * ( 1 - e ** 2 ) / ( w ** 3 ).to_f

      # 卯酉線曲率半径を計算
      n = r_x / w.to_f

      # 距離を計算
      d  = ( a_y * m ) ** 2
      d += ( a_x * n * Math.cos( p ) ) ** 2
      d  = Math::sqrt( d )

      return d
    end
  end
end