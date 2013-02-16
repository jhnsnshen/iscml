% general function to determine the type of parity check matrix specified
% by sim_param.parity_check_matrix


function hmat_type = GetHmatType( pcm )

   if isempty(pcm)    % default to dvb-s2
   pcm = 'InitializeDVBS2';
   end


if ~isempty(strfind( pcm, 'InitializeDVBS2' ))
    hmat_type = 'cml_dvbs2';
    
elseif strcmp( pcm(end-3:end), 'pchk')
    hmat_type = 'pchk';
    
elseif strcmp( pcm(end-4:end), 'alist')
    hmat_type = 'alist';
    
elseif strcmp( pcm(end-2:end), 'mat')
    hmat_type = 'mat';
    
else
    hmat_type = 'not_supported';
    
end

end