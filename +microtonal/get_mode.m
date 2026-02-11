
function mode_steps = get_mode(tet, mode_name)
    % GET_MODE Retrieves mode definition for a given TET system
    %
    % Example:
    %   steps = get_mode(12, 'major');
    %   steps = get_mode(31, 'harmonic');
    
    switch tet
        case 12
            modes = microtonal.get_12tet_modes();
        case 19
            modes = microtonal.get_19tet_modes();
        case 31
            modes = microtonal.get_31tet_modes();
        case 53
            modes = microtonal.get_53tet_modes();
        otherwise
            error('No mode definitions available for %d-TET. Define your own!', tet);
    end
    
    if ~isfield(modes, mode_name)
        error('Mode "%s" not defined for %d-TET', mode_name, tet);
    end
    
    mode_steps = modes.(mode_name);
end
