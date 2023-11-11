"""
### Usando a diferença de Frames
$Foreground = | I_t - I_{t-1} | > T$
"""

def difFrames(frames): 
    n = frames.shape[0];
    print(n) 
    dif = []
    for i in range(n-1, 0, -1):
        #print(i, i-1)
        dif.append(cv2.absdiff(frames[i], frames[i-1]))

    return np.array(dif)

dif = difFrames(frames)

#### Visualizando o vídeo sem o background
for frame in dif:
    cv2.imshow('Video Playback', frame)
    if cv2.waitKey(25) & 0xFF == 27:  # Press Esc key to exit
        break
    time.sleep(1 / 30)

cv2.destroyAllWindows()

"""
### Usando a mediana para subtrair o fundo 
$Foreground_t = |I_t - B | > T $, onde $B = median(I_1, I_2, ... , I_k)$
"""

def difFramesMedian(frames, k, threshold=30):
    newFrames = [] 
    background_frames = frames[-k:]
    median_frame = np.median(background_frames, axis = 0).astype(np.uint8)


    for i, frame in enumerate(frames):
        abs_diff = cv2.absdiff(frame, median_frame)

        abs_diff = cv2.cvtColor(abs_diff, cv2.COLOR_BGR2GRAY)

        _, foreground_mask = cv2.threshold(abs_diff, threshold, 255, cv2.THRESH_BINARY)

        newFrames.append(foreground_mask)

    return np.array(newFrames)

difMedian = difFramesMedian(frames, 60, 150)

for frame in difMedian:
    cv2.imshow('Video Playback', frame)
    if cv2.waitKey(25) & 0xFF == 27:  # Press Esc key to exit
        break
    time.sleep(1 / 30)

cv2.destroyAllWindows()