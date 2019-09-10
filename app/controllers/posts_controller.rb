class PostsController < ApplicationController
  before_action :set_post, only: :show
  def index
    @nine_gag = extraer_datos_9gag
    @filtrado = filtrar(@nine_gag)
    ninegag_a_posts(@filtrado)

    @titulos_reddit, @imagenes_reddit, @fuentes_reddit = extraer_datos_reddit
    reddit_a_posts(@titulos_reddit, @imagenes_reddit, @fuentes_reddit)

    @titulos_imgur, @imagenes_imgur, @fuentes_imgur = extraer_datos_imgur
    imgur_a_posts(@titulos_imgur, @imagenes_imgur, @fuentes_imgur)

    @posts = Post.all.order("created_at DESC")

    @search = params["search"]
    if @search.present?
      @titulo = @search["titulo"]
      @posts = Post.where("titulo LIKE ?", "%#{@titulo}%")
    end

  end

  def filtrar(arreglo)
    arreglo.reject { |i| i[:video]}
  end

  def ninegag_a_posts(arreglo)
    arreglo.each do |i|
      unless Post.find_by(url_imagen: i[:media][:image])
        temp_title = i[:title].gsub("&#039;","'")
        Post.create(titulo: temp_title, url_imagen: i[:media][:image], fuente: i[:url])
      end
    end
  end

  def extraer_datos_reddit
    require 'rest-client'
    require 'nokogiri'

    pagina = RestClient.get('https://www.reddit.com/r/memes/')
    doc = Nokogiri::HTML.parse(pagina)

    posts = doc.css('._1poyrkZ7g36PawDueRza-J')

    titulos = Array.new
    imagenes = Array.new
    fuentes = Array.new

    posts.each do |post|
      titulos << post.css('a').css('._eYtD2XCVieq6emjKBH3m').text
      temp = post.css('a').css('._2_tDEnGMLxpM6uOa2kaDB3').attr('src')
      temp2 = post.css('a').css('.SQnoC3ObvgnGjWt90zD9Z').attr('href')
      if temp != nil
        imagenes << temp.value
      end
      if temp2 != nil
        fuentes << "https://www.reddit.com" + temp2.value
      end
    end
    titulos.shift
    titulos.shift
    fuentes.shift
    fuentes.shift
    [titulos, imagenes,fuentes]
  end

  def extraer_datos_imgur
    require 'net/http'
    require 'json'

    uri = URI('https://api.imgur.com/3/g/memes/')
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Client-ID 44073d4814f21ac"

    res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https'){|http|
      http.request(req)
    }
    data = JSON.parse(res.body)

    var = 0
    var_img = 0
    titulos = Array.new
    imagenes = Array.new
    fuentes = Array.new

    until var == data["data"].length do
      if data['data'][var]['images'] == nil
        var += 1
      else
        until var_img == data["data"][var]["images"].length do
          if data["data"][var]['images'][var_img]['animated']
            var_img += 1
          else
            titulos << data["data"][var]['title']
            fuentes << data["data"][var]['link']
            imagenes << data['data'][var]['images'][var_img]['link']
            var_img = data["data"][var]["images"].length
          end
        end
        var += 1
        var_img = 0
      end
    end
    [titulos, imagenes, fuentes]

  end

  def imgur_a_posts(titulos, imagenes, fuentes)
    var = 0
    until var == imagenes.length do
      unless Post.find_by(url_imagen: imagenes[var])
        Post.create(titulo: titulos[var], url_imagen: imagenes[var], fuente: fuentes[var])
      end
      var += 1
    end
  end

  def extraer_datos_9gag
    NineGag.hot[:data]
  end

  def reddit_a_posts(titulos, imagenes, fuentes)
    var = 0
    until var == imagenes.length do
      unless Post.find_by(url_imagen: imagenes[var])
        Post.create(titulo: titulos[var], url_imagen: imagenes[var], fuente: fuentes[var])
      end
      var += 1
    end
  end

  def show
  end

  def set_post
    @post = Post.find(params[:id])
  end
end