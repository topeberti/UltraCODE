import numpy as np
from scipy.signal import hilbert
from skimage.transform import resize
from scipy.fftpack import fft, fftfreq
from PIL import Image      
from os import listdir
from pathlib import Path   
import tifffile as tf

def napari_read_tiff(pathlibpath,start=0, folder=False, nframes='all'):
    '''
    Read a multiframe tif image and loads it in a numpy array
    '''
    
    if not folder:
        with Image.open(str(pathlibpath), mode='r') as img:
            stack = []
            if nframes == 'all':

                try:
                    for i in range(start,img.n_frames):
                        img.seek(i)
                        stack.append(np.array(img))
                except:
                    print(i)
                    pass
        #     else:
        #         for i in range(start,nframes):
        #             img.seek(i)
        #             stack.append(np.array(img))
    if folder:
        files = listdir(pathlibpath)
        stack = []
        for file in files:
            filepath = pathlibpath / file
            with Image.open(str(filepath),mode='r') as img:
                stack.append(np.array(img))
    return np.transpose(np.array(stack), (1, 2, 0))


def write_tiff(vol,path_to_save):

    vol = np.transpose(vol,(2,0,1))

    tf.imwrite(path_to_save,vol)


class FFTAnalyze:
    
    def __init__(self):
        
        self.ref = None #Reference signal ndarray 1D
        self.ref_loaded = False #Control var, True if reference signal is loaded
        self.left = 0
        self.right = 0
        
    def set_ref_window(self,signal ,left ,right): #Set reference signal window
        
        self.left = left
        
        self.right = right
        
        self.ref = np.zeros(signal.shape) #reference 0s signal
        
        self.ref[left:right] = signal[left:right] #Copying window values from signal to reference
        
        self.ref_loaded = True 
        
        return self.ref 
    
    def get_ref(self): #Returns reference signal if already computed
        
        if not self.ref_laoded :
            
            print("No reference signal computed")
            
            return None
        
        return self.ref
    
    def backwall_window_volume(self,volume,lam_thickness,c_mat,fs): #backwall window 3d
        
        return np.apply_along_axis(self.backwall_window,2,volume,lam_thickness,c_mat,fs)
    
    
    def backwall_window(self,signal,lam_thickness,c_mat,fs):#signal should be analityc
        
        env = np.abs(signal) #envelope
        
        #First we get the window
        
        arg_max = np.argmax(env)  #Materials entry
        fin_mat = np.int( arg_max + lam_thickness * fs/ c_mat ) #theorical Materials exit
        
         # Returns the real materials exit
        
        if (fin_mat > 500):
            
            x_out = 0
        
        else:
           
            rango = range(fin_mat-5,fin_mat+5) #range around materials exit
            x_out = (fin_mat-5+np.argmax(env[rango])) # materials exit - 5 + windows max index
            
        
        # slicing to get the window
        l = len(signal) #signals len
        
        if (x_out != 0): # if is not back-wall
            
            result = np.zeros(shape=signal.shape) #zeros shaped as signal
            
            result[self.left:self.right] = signal[int(x_out-np.floor((self.right-self.left)/2)):int(x_out+np.floor((self.right-self.left)/2))] #copy window from signal to result
            
            return result
        
        if (x_out == 0): #means is back-wall due to arg_out func
            
            return np.zeros(shape=self.ref.shape) # zeros shaped as signal
        
        
        
    def backscattered_window_volume(self,volume,mask1,mask2):
        
        return np.apply_along_axis(self.backscattered_window,2,volume,mask1,mask2)
        
        
    def backscattered_window(self,signal,mask1,mask2): #Gets signal windowed in backscattered
        
        cropped = np.zeros(shape=signal.shape)
        
        cropped[mask1:mask2] = signal[mask1:mask2]
        
        return cropped 
    
    
    def fourier_volume(self,volume,fs): #signal must be windowed
    
        frec_vec = fftfreq(self.ref.size, d=1/fs*1e6)
        
        fft_ref = np.abs(fft(self.ref)) 
        
        fft_signal = np.abs(np.apply_along_axis(fft,2,volume))
        
        return frec_vec,fft_ref,fft_signal
    
    def fourier(self,signal,fs): #signal must be windowed
        
        frec_vec = fftfreq(self.ref.size, d=1/fs*1e6)
        
        fft_ref = np.abs(fft(self.ref))
        
        fft_signal = np.abs(fft(signal)) 
        
        return frec_vec,fft_ref,fft_signal
        
    
    def normalize(self,signal):
        
        return signal / np.abs(fft(self.ref))
        

class AspectRatio:
    
    def __init__(self):
        
        pass
    
    def ratio(self,x,y,x1,y1,axis = -1):
        
        #Computes new shape for the image where x and y are real measures of the object 
        #x1,y1 are unit per pixel ratios of each dimension in the image
        
        if x1 >= y1:
            
            axis = 0
            
            axis2 = 1
        
        else:
            
            axis = 1
            
            axis2 = 0
        
        sample = [x,y] #sample shape
        image = [x1,y1] #image shape
    
        
        sample_ratio = sample[axis]/sample[axis2]
        image_ratio = image[axis]/image[axis2]
        new_ratio = sample_ratio / image_ratio
        
        if axis: # axis = 1
        
            return (int(x1/new_ratio),y1)
        
        else:
            
            return (x1,int(y1/new_ratio))
        
    def reshape(self,x,y,image): # x y z
        
        if len(image.shape) == 2:
        
            x1 = image.shape[0]
            y1 = image.shape[1]

            new_shape = self.ratio(x,y,x1,y1)

            return resize(image, new_shape)
        
        x1 = image.shape[0]
        y1 = image.shape[1]
        z1 = image.shape[2]

        new_shape = self.ratio(x,y,x1,y1)

        return resize(image, new_shape + (z1,))


class RfAnalyze: 
    
    def __init__(self,data=[], save = True, fs = 40,axis = 2):
        
        data = data.astype('int32')
        media = np.mean(data)
        data = data - media   
        
        self.data = data
        self.fs = fs
        self.hilbert = []
        self.saved = False
        self.viewer = None
        self.analytic()
    
    def analytic(self,save = True, visualzie = False):
        
        if save:
            self.saved = save
            self.hilbert = hilbert(self.data)
            return self.hilbert
        
        return hilbert(self.data)
            
    
    def envelope(self):
        
        if self.saved:
            print("Using saved")
            
            data = self.hilbert
        
        else:
            
            data = self.analytic(False)
            
        result = np.abs(data)
        
        return result
    
    def inst_phase(self):
        
        if self.saved:
            print("Using saved")
            
            data = self.hilbert
        
        else:
            
            data = self.analytic(False)
        
        def func(x): 
            return (np.angle(x))
        
        result = np.apply_along_axis(func,2,data)

        return result
    
    def inst_freq(self):
        
        if self.saved:
            print("Using saved")
            
            data = self.hilbert
        
        else:
            
            data = self.analytic(False)
        
        def func(x):
            
            return (np.diff(np.unwrap(np.angle(x))) / (2.0*np.pi) * self.fs)
        
        result = np.apply_along_axis(func,2,data)
        
        return result
        