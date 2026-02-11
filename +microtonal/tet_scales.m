% ========================================================================
% MICROTONAL MUSIC FRAMEWORK
% A flexible system for working with arbitrary TET (Tone Equal Temperament)
% systems and defining modes/scales within them
% ========================================================================

% ========================================================================
% CORE FUNCTION: Generate scale from TET system and mode definition
% ========================================================================
function frequencies = tet_scales(root_freq, tet, mode_steps, num_octaves)
    % GET_SCALE Generate frequencies for a scale in any TET system
    %
    % Inputs:
    %   root_freq: Root frequency in Hz (e.g., 440 for A4, 261.63 for C4)
    %   tet: Number of equal divisions per octave (e.g., 12, 19, 31, 53)
    %   mode_steps: Array of scale degrees within the TET (e.g., [0,2,4,5,7,9,11] for 12-TET major)
    %   num_octaves: Number of octaves to generate (default: 1)
    %
    % Output:
    %   frequencies: Array of frequencies for the scale
    %
    % Example:
    %   major_scale = get_scale(261.63, 12, [0,2,4,5,7,9,11], 2);
    %   custom_31tet = get_scale(440, 31, [0,5,10,13,18,23,28], 1);
    
    if nargin < 4
        num_octaves = 1;
    end
    
    frequencies = [];
    
    % Generate frequencies for each octave
    for octave = 0:(num_octaves - 1)
        for i = 1:length(mode_steps)
            step = mode_steps(i) + (octave * tet);
            freq = root_freq * (2^(step / tet));
            frequencies = [frequencies, freq];
        end
    end
    
    % Add the final root note of the last octave
    frequencies = [frequencies, root_freq * (2^num_octaves)];
end

% ========================================================================
% EXAMPLE USAGE AND DEMONSTRATIONS
% ========================================================================
% 
% fprintf('=== MICROTONAL MUSIC FRAMEWORK DEMO ===\n\n');
% 
% % Example 1: Standard 12-TET major scale
% fprintf('1. C Major scale (12-TET):\n');
% c4 = note_to_freq('C4');
% major_12 = tet_scales(c4, 12, get_mode(12, 'major'), 1);
% fprintf('   Frequencies: ');
% fprintf('%.2f ', major_12);
% fprintf('Hz\n\n');
% 
% % Example 2: 12-TET Dorian mode
% fprintf('2. D Dorian scale (12-TET):\n');
% d4 = note_to_freq('D4');
% dorian_12 = tet_scales(d4, 12, get_mode(12, 'dorian'), 1);
% fprintf('   Frequencies: ');
% fprintf('%.2f ', dorian_12);
% fprintf('Hz\n\n');
% 
% % Example 3: 31-TET major scale
% fprintf('3. C Major scale (31-TET - microtonal):\n');
% major_31 = tet_scales(c4, 31, get_mode(31, 'major'), 1);
% fprintf('   Frequencies: ');
% fprintf('%.2f ', major_31);
% fprintf('Hz\n\n');
% 
% % Example 4: Custom 31-TET mode
% fprintf('4. Custom scale in 31-TET:\n');
% custom_steps = [0, 4, 7, 8, 13, 17, 21, 26];  % Your own invention!
% custom_scale = tet_scales(c4, 31, custom_steps, 1);
% fprintf('   Frequencies: ');
% fprintf('%.2f ', custom_scale);
% fprintf('Hz\n\n');
% 
% % Example 5: 19-TET exotic scale
% fprintf('5. Exotic scale (19-TET):\n');
% exotic_19 = tet_scales(c4, 19, get_mode(19, 'exotic1'), 1);
% fprintf('   Frequencies: ');
% fprintf('%.2f ', exotic_19);
% fprintf('Hz\n\n');
% 
% % Example 6: Full chromatic scale in 31-TET (all 31 tones in one octave)
% fprintf('6. Full chromatic (31-TET) - first 10 notes:\n');
% chromatic_31 = tet_scales(c4, 31, 0:30, 1);
% fprintf('   Frequencies: ');
% fprintf('%.2f ', chromatic_31(1:10));
% fprintf('... (31 total tones)\n\n');
% 
% fprintf('=== HOW TO ADD YOUR OWN MODES ===\n');
% fprintf('Edit the get_31tet_modes() function and add:\n');
% fprintf('  modes.my_scale = [0, 3, 7, 11, 15, 19, 23, 27];\n');
% fprintf('Then use it with: get_scale(root_freq, 31, get_mode(31, ''my_scale''), 1)\n\n');
% 
% fprintf('=== QUICK REFERENCE ===\n');
% fprintf('• 12-TET: Standard Western music (semitones)\n');
% fprintf('• 19-TET: Good for both meantone and superpyth temperaments\n');
% fprintf('• 31-TET: Excellent 5-limit just intonation, pure thirds\n');
% fprintf('• 53-TET: Extremely accurate Pythagorean tuning\n\n');
% 
% % ========================================================================
% % TEMPLATE FOR DEFINING YOUR OWN TET SYSTEM
% % ========================================================================
% function modes = get_custom_tet_modes()
%     % Template: Define your own TET system modes here
%     % For example, if you want to work with 17-TET, 22-TET, or any other division
% 
%     modes = struct();
% 
%     % Define your modes as arrays of scale degrees
%     % Example for 17-TET:
%     % modes.my_mode = [0, 3, 6, 8, 10, 13, 15];
% 
%     % Add as many modes as you want!
% end