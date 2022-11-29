% Modified: A. Ibanez 16/11/2022
%% *** FILE CONTAINING ADQUISITION DATA ***
archivo ='.\adq_data\basurilla';

    [data_set, cfg]= STII_load_file(archivo);
    
disp('Acquisition description:')
cfg


%images of captured data:
data_range=[-2^(cfg.n_bits-1) 2^(cfg.n_bits-1)];
figure(1);

string1=['/' num2str(cfg.n_acquisitions) ' Focal law: '];
string2=['/' num2str(cfg.n_focal_law)];

for acq=1:cfg.n_acquisitions

    for fl=1:cfg.n_focal_law
        imagesc(data_set(:,:,fl,acq));
        title(['Acquisition: ' num2str(acq) string1 num2str(fl) string2]);
        xlabel('A-scans');
        ylabel('Samples');
        caxis(data_range);
        colorbar();
        drawnow();
        pause(.5);
    end
end


