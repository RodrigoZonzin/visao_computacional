using VideoIO, ImageView, Images, GLMakie, DSP, Statistics, ImageMorphology


cap = VideoIO.openvideo("mm3-curto.mp4")

    frame=read(cap)
    frame=imresize(frame,480,720)
    obs_img = GLMakie.Observable(GLMakie.rotr90(frame))
    scene = GLMakie.Scene(camera=GLMakie.campixel!, resolution=reverse(size(frame)))
    GLMakie.image!(scene, obs_img)
    display(scene)
      
   
    seek(cap,100)
    framei=read(cap)
    frame=read(cap)
    
    mask=processa(framei,frame) #funcao que retira o fundo do cenario com diferença de frames
    
    mask_label=label_components(mask)
    boxes=component_boxes(mask_label)
    box=boxes[1]
    masked=mask.*frame
    sprite_padrao=masked[box.indices[1],box.indices[2]]    
    function main()
   
    seek(cap,90)
    for i=1:200
    frame=read(cap)
    ###preparar a imagem em tons de cinza
    
    f_cinza = convert(Array,channelview(Gray.(frame))).*255
    s_cinza = convert(Array,channelview(Gray.(sprite_padrao))).*255
    ###normalizar as imagens
    f_cinza = (f_cinza.-mean(f_cinza))/std(f_cinza)
    s_cinza = (s_cinza.-mean(s_cinza))/std(s_cinza)
    
   #correlacao com tons de cinza
   corr=imfilter(f_cinza,s_cinza)

     
   ###imagem colorida
   f_cor = convert(Array,(channelview(frame))).*255
   s_cor = convert(Array,(channelview(sprite_padrao))).*255
   
   global corrc=zeros(size(f_cor[1,:,:]));
   for n=1:3
    f_cor[n,:,:] = (f_cor[n,:,:].-mean(f_cor[n,:,:]))/std(f_cor[n,:,:])
    s_cor[n,:,:] = (s_cor[n,:,:].-mean(s_cor[n,:,:]))/std(s_cor[n,:,:])
    global corrc += abs.(imfilter(f_cor[n,:,:],s_cor[n,:,:])./3)
   end
   
   
   
   ###pegar a maior correlação na matriz
   pos=argmax(corrc)
   corte(pos,sprite_padrao,frame)  
   end
   VideoIO.close(cap)

 
   
end 
    function processa(framei,frame)
    hsv=HSV.(framei)
    hsv= channelview(hsv)
    maski = hsv[3,:,:].>.5

    hsv=HSV.(frame)
    hsv= channelview(hsv)
    mask = hsv[3,:,:].>.5
    
    mask=abs.(mask-maski)
    mask=dilate(mask)
    mask=erode(mask)
    mask=dilate(mask)
    mask=dilate(mask)
    mask=erode(mask)
    mask=erode(mask)
    mask=erode(mask)
    mask=erode(mask)
    mask=dilate(mask)
    mask=dilate(mask)
 return mask
end
    
function corr_janela_hist(tela,sprite)
    ed,hist_sprite=build_histogram(sprite)
   
    function histograma(janela)
        ed,hist_janela = build_histogram(janela)
        return xcorr(hist_sprite, hist_janela)
       end
      

    # Aplica a função de correlação a uma janela do tamanho do sprite
    s=size(sprite)
    s[1] %2 == 0 ? l=s[1]+1 : l=s[1]
    s[2] %2 == 0 ? c=s[2]+1 : c=s[2]
    imshow(tela)
    return mapwindow(histograma, tela,(l,c) ) 
end
   
function corr_janela(sprite,tela)
    
   
    function correlacao(janela)
        return xcorr(sprite[:], janela[:])
    end
     
    # Aplica a função de correlação a uma janela do tamanho do sprite
    s=size(sprite)
    s[1] %2 == 0 ? l=s[1]+1 : l=s[1]
    s[2] %2 == 0 ? c=s[2]+1 : c=s[2]
    return mapwindow(correlacao, tela,(l,c) ) 
end


function dist_janela(sprite,tela)
    function distancia(janela)
        sprite=imresize(sprite,size(janela))
        return sqrt(sum((sprite - janela).^2))
       end
      

    # Aplica a função de distancia a uma janela do tamanho do sprite
    s=size(sprite)
    s[1] %2 == 0 ? l=s[1]+1 : l=s[1]
    s[2] %2 == 0 ? c=s[2]+1 : c=s[2]
    return mapwindow(distancia, tela,(l,c) ) 
end

function dist_janela_hist(sprite,tela)
    ed,hist_sprite=build_histogram(sprite)
   
    function distancia(janela)
        ed,hist_janela=build_histogram(janela)

        return sqrt(sum((hist_sprite - hist_janela).^2))
       end
      

    # Aplica a função de distancia a uma janela do tamanho do sprite
    return mapwindow(distancia, tela,(1,257) ) 
end
   
    function corte(pos,sprite,img)
       
        s_img=size(img)
        s=Int64.(round.(size(sprite)./2))
    
        mx = pos[1]+s[1]>s_img[1] ? s_img[1] : pos.I[1]+s[1]
        my = pos[2]+s[2]>s_img[2] ? s_img[2] : pos[2]+s[2]
        nx = pos[1]-s[1]<1 ? 1 : pos[1] - s[1]
        ny = pos[2]-s[2]<1 ? 1 : pos[2] - s[2]
        det=img[nx:mx,ny:my]
        sprite=imresize(sprite,200,200)
        det=imresize(det,200,200)
        img=imresize(img,200,400)
        n_img = [sprite det; img]
        obs_img[] = GLMakie.rotr90(n_img)
        sleep(1/15)
        return n_img
    end