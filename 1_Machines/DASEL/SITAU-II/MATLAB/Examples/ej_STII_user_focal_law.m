
n_emiters=128;  %number of emiters for every single focal law
n_laws=4;      %number of focal laws.

fl=(1:n_delays).';         %a silly focal law
fl=repmat(fl,1,n_laws);    %n_laws times a silly focal law 

fname='.\adq_data\silly_focal_laws.TXT';
STII_user_focal_law(fl, fname);
text=[num2str(n_laws) ' focal laws for a ' num2str(n_emiters)...
     ' elements array recorded in ' fname];
disp(text);
