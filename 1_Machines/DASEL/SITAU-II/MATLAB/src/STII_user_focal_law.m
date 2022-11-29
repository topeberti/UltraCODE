function STII_user_focal_law (lf, f_name)

% STII_user_focal_law (lf, f_name))
%
%Guarda leyes focales para emisión en un archivo compatible con la aplicacion 
%ScanView. 
%lf: es una matriz Ne x Nf, donde Ne es el numero de retardos de que consta
%cada ley focal y Nf el numero de leyes focales que se han definido. Los 
%retardos de cada ley focal se expresan en microsegundos.
%f_name: nombre del archivo de texto en que se guardaran las leyes focales
%con formato compatible con el  definido en la aplicacion ScanView v.1.0.33:
%
%- Cada linea es una ley focal. El fin de linea es el caracter especial "\n"
%- Dentro de la linea los retardos son en microsegundos y eston separados por
%  un espacio, da igual si el separador de los decimales es '.' o ','
%- El numero de retardos debe ser el mismo para todas las leyes focales 
%  (lineas del archivo), y debe ser igual o menor que el numero de canales
%  del equipo.
%
% 24/11/2022
% A. Ibanez ITEFI-CSIC 

if nargin ~= 2
%     error ('Numero de argumentos incorrecto') 
    error ('Bad number of arguments') 
end

[senda, nombre, ext]=fileparts(f_name);
filename = fullfile(senda, [nombre,'.txt']);
fi=fopen(filename, 'w');

if fi <0
%     error('No puede crearse el archivo')
      error('File can''t be created')
end

[nr, nl]=size(lf);

for i=1:nl
   fprintf(fi,'%1.3f ',lf(1:(end-1),i));
   fprintf(fi,'%1.3f\n',lf(end,i));
end
fclose(fi);