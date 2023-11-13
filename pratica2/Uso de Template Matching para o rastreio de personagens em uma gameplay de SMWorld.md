
	Rodrigo José Zonzin
	212050002
	Linguagem utilizada: Python

### Objetivo 
1. Utilizar as técnicas de correlação para encontrar os personagens Mário e Bowser no vídeo *"SMWorld.mp4"*. 
2. Comparar as técnicas de correlação através de métricas estatísticas 
3. Apresentar os resultados 
## Preparando o ambiente

Um vídeo é matematicamente descrito como a quadrupla a seguir: 
$$V = (N, W, H, C)$$
onde $N = \text{número de Frames}$, $W= \text{width/largura}$, $H = \text{heigth/altura}$ e $C = channels/canais$

Para manipularmos um vídeo, podemos ler os $N$ frames da coleção e armazená-los em um array multidimensional. O código a seguir apresenta os passos tomados em Python utlizando as bibliotecas NumPy e OpenCV. 

~~~Python 
import cv2
import numpy as np

cap = cv2.VideoCapture('SMWorld.mp4')

frames = []

while True:
	ret, frame = cap.read()            #lê o proximo frame

	if not ret:                        #apos ultimo frame, retorna False
		print("Leitura completa!")
		break

	frames.append(frame)               #adiciona à lista frames o frame atual 

cap.release()                          #libera o leitor do opencv
~~~

Transformamos o objeto do tipo lista do Python para um objeto *np.ndarray*, pois ele tem atributos e métodos interessantes: as dimensões do array, produto interno e etc
~~~python 
frames = np.array(frames)
~~~

### Definindo uma ROI para o Mário

No frame 501, podemos visualizar o Mário parado em um dos obstáculos. Utilizamos esse frame para obter um recorte que será utilizado para a convolução/correlação nas cenas do vídeo. Obtemos uma coordenada aproximada no plano $WH$ e retiramos uma faixa de 30 pixeis tanto na largura quanto na altura.

~~~python 
mario = frames[501, 170:200, 50:80, :]
mario = cv2.cvtColor(mario, cv2.COLOR_BGR2GRAY)    #convertendo para grayscale
~~~

![[templateCena.png]]

Após essa etapa, estamos prontos para utilizar uma operação de convolução utilizando a função de correlação cruzada normalizada como métrica de *matching*. Dada uma imagem $I$ e um template $T$, temos: 
$$R(x, y) = \frac{\sum_{x', y'}(T'(x', y') \cdot I'(x+x', y+y')) }{\sqrt{\sum_{x',y'}T'(x1, y1)^{2} \cdot \sum_{x1, y1} I'(x+x', y+y')^2 }}$$
Essa expressão equivale ao produto interno normalizado entre os elementos da Imagem e do Template. Uma notação mais concisa é a seguinte: 
$$R(x,y) = \frac{T\cdot I}{||T||\cdot ||I||}$$
A biblioteca *OpenCV* oferece um ambiente facilitado para a implementação da convolução com a métrica desejada. Definimos uma função para um vídeo $Frames$ como segue: 

~~~python 
def calcCorrelation(template, frames):
	w, h = template.shape
	
	for frame in frames:
		framei = frame.copy()      #uma copia para nao alterar o frame original
		
		result = cv2.matchTemplate(framei, template, cv2.TM_CCOEFF_NORMED)
		
		min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)
		location = max_loc
		bottom_right = (location[0] + w, location[1] + h)
		
		#desenha um retangulo na posicao de match
		cv2.rectangle(framei, location, bottom_right, 255, 4)
		#[...] plota framei, adciona titulo e etc
~~~

### Resultados
Para testarmos o rastreamento do Mário ao longo do vídeo, escolhemos aleatoriamente 9 cenas sequenciais entre os 5840 frames possíveis. A imagem a seguir apresenta os resultados do rastreamento: 

![[frames_correlacao.png]]

Das 9 cenas, nossa metodologia localizou o personagem precisamente 7 vezes. Dentre as 7 localizações bem sucedidas, em 5 ele estava posicionado no mesmo sentido que o template e em 2 ele estava voltado para o sentido oposto. 

A maior correlação ocorreu no $frame \ 3865$ ($R(x,y) = 0.9119$), onde o personagem se encontra disposto de maneira muito similar à cena onde o template foi retirado. Nestes frames, ele se encontra no chão, voltado para o sentido *esquerda-direita* e parado de frente a um obstáculo. 

Nas 2 falhas o personagem estava na cena, mas foi confundido com outros objetos.  
1. No $frame \ 4900$, o personagem estava saltando. Neste caso, elencamos como hipótese o fato de que a sua capa possa ter deslocado a distribuição dos pixels para valores mais claros.
2. No $frame \ 2816$, por volta de $\textit{1min 35s}$, a cena sofre uma sequência de mudanças abruptas de cor. De uma cena escura, vários frames tornam-se mais claros, o que pode ter contribuído para que a distribuição de dados da janela da cena tenha tido uma correlação mais alta com a distribuição do template. 

Embora a mudança na cor dos pixels pareça ter contribuído pontualmente para a confusão do modelo, não temos evidência estatística de que exista uma relação entre a mudança na cor média da cena e um *tracking* mais eficiente do personagem. 
![[corvscorrelacao 1.png]]

### Repetindo a mesma metodologia para o Bowser
Template escolhido no frame $2630$, nas posições $W = [200,285]$ e $H=[25, 130]$
![[templateCenaBowser.png]]

### Alguns resultados: 
![[frames_correlacaoBowser.png]]

Como podemos observar, a localização do Bowser parece ter sido mais eficiente. Ele foi localizado em todas a cenas em que está presente.  Uma maior quantidade de dados, uma vez que a janela é maior, se traduz em uma discriminação mais apurada das feições presentes no histograma da cena. 

1. No mesmo sentido que o template
2. Sem  e com o dragão 
3. Rotacionado (*de cabeça para baixo*)
4. De tamanhos diversos
5. Com o sorriso e os olhos em sentidos opostos 

Quando o Bowser não estava presente na cena, a maior correlação se deu com o Mário. Possivelmente, isso se explica em razão de o Mário ser o objeto com a maior distribuição de pixeis claros na tela. 
### Código
O código está disponível e pode ser avaliado no seguinte repositório do GitHub: 
[https://github.com/RodrigoZonzin/visao_computacional](https://github.com/RodrigoZonzin/visao_computacional)
