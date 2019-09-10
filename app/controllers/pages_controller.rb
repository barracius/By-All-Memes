class PagesController < ApplicationController
  def home
    @a = NineGag.hot[:data]
    @filtrado = filtrar(@a)
  end

  def filtrar(arreglo)
    arreglo.reject { |i| i[:video] == true }
  end

end