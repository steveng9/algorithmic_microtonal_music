addpath('sounds');


function play_notation_music_main()
    % sound_function = @crystal_bowl_with_pop;
    sound_function = @ocarina_sound;
    % [voices, tonic, mode, eighth_note_duration] = parse_music_notation('./first_text_music.txt');
    [voices, tonic, mode, eighth_note_duration] = parse_music_notation('./Xenakis_SixChansons.txt');

    validate_measure_lengths(voices);
    audio_buffer = generate_audio(voices, tonic, mode, eighth_note_duration, sound_function);
    play_with_blocking(audio_buffer);
end



function [voices, tonic, mode, eighth_note_duration] = parse_music_notation(filename)

    REST_NOTATION = 'r';
    REST_MARKER = NaN;

    %% Parse the file
    fid = fopen(filename, 'r');
    if fid == -1
        error('Could not open file: %s', filename);
    end
    
    % Read entire file
    file_content = fread(fid, '*char')';
    fclose(fid);
    
    % Extract metadata
    lines_ = strsplit(file_content, '\n');
    
    % Remove comment lines (lines starting with #)
    lines = lines_(~startsWith(strtrim(lines_), '#'));
    file_content = strjoin(lines, newline);

    % Find qtr_note tempo
    tempo_line = find(contains(lines, 'qtr_note'), 1);
    tempo_match = regexp(lines{tempo_line}, 'qtr_note\s*=\s*(\d+)', 'tokens');
    qtr_note_bpm = str2double(tempo_match{1}{1});
    eighth_note_duration = 60 / (qtr_note_bpm * 2);  % Duration in seconds
    
    fprintf('Tempo: quarter note = %d BPM\n', qtr_note_bpm);
    fprintf('Eighth note duration: %.3f seconds\n', eighth_note_duration);
    
    % Find key signature
    key_line = find(contains(lines, 'major') | contains(lines, 'minor'), 1);
    key_text = strtrim(lines{key_line});
    fprintf('Key: %s\n', key_text);
    
    % Parse key to get scale
    [tonic, mode] = parse_key_signature(key_text);
    
    %% Extract all notation blocks between [ and ]
    % Find all matching pairs of outermost brackets
    notation_blocks = {};
    pos = 1;
    while pos <= length(file_content)
        % Find next opening bracket
        bracket_start = strfind(file_content(pos:end), '[');
        if isempty(bracket_start)
            break;
        end
        bracket_start = bracket_start(1) + pos - 1;
        
        % Find matching closing bracket (count nesting)
        depth = 0;
        bracket_end = -1;
        for i = bracket_start:length(file_content)
            if file_content(i) == '['
                depth = depth + 1;
            elseif file_content(i) == ']'
                depth = depth - 1;
                if depth == 0
                    bracket_end = i;
                    break;
                end
            end
        end
        
        if bracket_end > 0
            notation_blocks{end+1} = file_content(bracket_start+1:bracket_end-1);
            pos = bracket_end + 1;
        else
            break;
        end
    end
    
    num_blocks = length(notation_blocks);
    fprintf('Found %d notation blocks\n', num_blocks);
    
    %% Parse each notation block
    all_voices_per_block = cell(num_blocks, 1);
    num_voices = -1;
    
    for block_idx = 1:num_blocks
        notation_section = notation_blocks{block_idx};
        
        % Split into voices (rows)
        voice_lines = strsplit(notation_section, '\n');
        voice_lines = voice_lines(~cellfun(@isempty, strtrim(voice_lines)));
        
        block_num_voices = length(voice_lines);
        
        % Check: all blocks must have same number of voices
        if num_voices == -1
            num_voices = block_num_voices;
        elseif num_voices ~= block_num_voices
            error('Block %d has %d voices, but previous blocks have %d voices', ...
                block_idx, block_num_voices, num_voices);
        end
        
        % Parse voices in this block
        voices_this_block = cell(num_voices, 1);
        
        for v = 1:num_voices
            voice_text = voice_lines{v};
            
            % Find all measures [...] in this voice
            measures = regexp(voice_text, '\[([^\]]+)\]', 'tokens');
            
            voice_measures = cell(1, length(measures));
            
            for m = 1:length(measures)
                measure_content = measures{m}{1};
                
                % Split by commas to get individual notes
                notes_text = strsplit(measure_content, ',');
                notes_text = strtrim(notes_text);
                
                % Parse each note
                measure_notes = [];
                for n = 1:length(notes_text)
                    note_str = notes_text{n};
                    
                    % Check if it's a rest
                    if startsWith(note_str, REST_NOTATION)
                        % Parse "r.duration"
                        parts = strsplit(note_str, '.');
                        if length(parts) == 2
                            duration = str2double(parts{2});
                            measure_notes = [measure_notes; REST_MARKER, duration, 0];  % [degree, duration, accidental]
                        end
                    else
                        % Parse "scale_degree[s|f].duration"
                        accidental = 0;  % 0=natural, 1=sharp, -1=flat
                        clean_note = note_str;
                        
                        if contains(note_str, 's')
                            accidental = 1;
                            clean_note = strrep(note_str, 's', '');
                        elseif contains(note_str, 'f')
                            accidental = -1;
                            clean_note = strrep(note_str, 'f', '');
                        end
                        
                        parts = strsplit(clean_note, '.');
                        if length(parts) == 2
                            degree = str2double(parts{1});
                            duration = str2double(parts{2});
                            measure_notes = [measure_notes; degree, duration, accidental];
                        end
                    end
                end
                
                voice_measures{m} = measure_notes;
            end
            
            voices_this_block{v} = voice_measures;
        end
        
        all_voices_per_block{block_idx} = voices_this_block;
    end
    
    fprintf('✓ All %d blocks have %d voices\n', num_blocks, num_voices);

    %% Concatenate all blocks into one continuous voice array
    voices = cell(num_voices, 1);
    for v = 1:num_voices
        all_measures_for_voice = {};
        for block_idx = 1:num_blocks
            block_measures = all_voices_per_block{block_idx}{v};
            all_measures_for_voice = [all_measures_for_voice, block_measures];
        end
        voices{v} = all_measures_for_voice;
    end
end



function [tonic, mode] = parse_key_signature(key_text)
    % Parse "C# major" or "F minor" etc.
    
    % Extract note name (first word)
    parts = strsplit(key_text);
    tonic_str = parts{1};
    
    % Add octave number
    tonic = [tonic_str, '1'];
    
    % Determine mode
    if contains(lower(key_text), 'major')
        mode = 'major';
    elseif contains(lower(key_text), 'minor')
        mode = 'minor';
    else
        mode = 'major';
    end
end



function validate_measure_lengths(voices)
    %% Validate combined voices
    num_measures = length(voices{1});
    num_voices = length(voices);
    
    % Check 1: All voices have same number of measures
    for v = 1:num_voices
        if length(voices{v}) ~= num_measures
            error('Voice %d has %d measures, but voice 1 has %d measures', ...
                v, length(voices{v}), num_measures);
        end
    end
    fprintf('✓ All voices have %d total measures\n', num_measures);
    
    % Check 2: Each measure column has same total duration
    for m = 1:num_measures
        total_duration = sum(voices{1}{m}(:, 2), 'omitnan');
        for v = 2:num_voices
            voice_duration = sum(voices{v}{m}(:, 2), 'omitnan');
            if abs(voice_duration - total_duration) > 0.01
                error('Measure %d: Voice 1 has %.1f eighths, Voice %d has %.1f eighths', ...
                    m, total_duration, v, voice_duration);
            end
        end
    end
    fprintf('✓ All measure durations align\n\n');
end
    


function audio_buffer = generate_audio(voices, tonic, mode, eighth_note_duration, sound_function)
    NUM_SCALE_OCTAVES = 5;  % For handling negative degrees
    BASE_SCALE_INDEX = 22;  % Allows -2 to +2 octave range

    % Get the scale
    modes = microtonal.get_12tet_modes();
    scale_pattern = modes.major;  % Default
    if strcmpi(mode, 'major')
        scale_pattern = modes.major;
    elseif strcmpi(mode, 'minor')
        scale_pattern = modes.minor;
    end
    
    base_freq = microtonal.note_to_freq(tonic);
    
    chromatic_scale = microtonal.tet_scales(base_freq, 12, modes.chromatic, NUM_SCALE_OCTAVES);
    diatonic_scale = microtonal.tet_scales(base_freq, 12, scale_pattern, NUM_SCALE_OCTAVES);
    
    octave_shifts = get_octave_shifts(voices);
    
    % Collect all notes from all voices
    all_notes = [];
    all_times = [];
    all_durations = [];
    
    current_time = 0;
    
    num_measures = length(voices{1});
    num_voices = length(voices);
    for m = 1:num_measures
        measure_start_time = current_time;
        
        for v = 1:num_voices
            measure_notes = voices{v}{m};
            voice_time = measure_start_time;
            
            for n = 1:size(measure_notes, 1)
                degree = measure_notes(n, 1);
                duration_eighths = measure_notes(n, 2);
                accidental = measure_notes(n, 3);
                duration_sec = duration_eighths * eighth_note_duration;
                
                if ~isnan(degree)
                    freq = calculate_frequency_with_accidental(...
                        degree, accidental, octave_shifts(v), ...
                        chromatic_scale, diatonic_scale, scale_pattern, BASE_SCALE_INDEX);
                    
                    all_notes = [all_notes, freq];
                    all_times = [all_times, voice_time];
                    all_durations = [all_durations, duration_sec];
                end
                voice_time = voice_time + duration_sec;
            end
        end
        
        % Advance to next measure
        measure_duration = sum(voices{1}{m}(:, 2), 'omitnan') * eighth_note_duration;
        current_time = current_time + measure_duration;
    end
    
    % Build the audio
    fprintf('Generating audio with %d notes...\n', length(all_notes));
    audio_buffer = microtonal.build_audio_buffer(all_notes, all_times, all_durations, sound_function);
end



function octave_shifts = get_octave_shifts(voices)
    num_voices = length(voices);
    octave_shifts = zeros(1, num_voices);
    if num_voices >= 2
        octave_shifts(num_voices-1) = -1;  % Second-to-bottom: down 1 octave
    end
    if num_voices >= 1
        octave_shifts(num_voices) = -2;  % Bottom: down 2 octaves
    end
end




function freq = calculate_frequency_with_accidental(degree, accidental, octave_shift, ...
                                                     chromatic_scale, diatonic_scale, scale_pattern, base_index)
    % Calculate frequency for a scale degree with optional accidental
    %
    % NOTE: Currently only works for 12-tet
    % 
    % degree: scale degree (1=tonic, 2=supertonic, etc.)
    % accidental: 0=natural, 1=sharp, -1=flat
    % octave_shift: octave adjustment for voice
    % chromatic_scale: full chromatic scale array
    % diatonic_scale: diatonic scale array
    % scale_pattern: intervals of the scale (e.g., [0,2,4,5,7,9,11] for major)
    % base_index: offset for indexing
    
    % First, get the diatonic note (natural)
    diatonic_index = base_index + round(degree) - 1 + (octave_shift * 7);
    
    % Clamp to valid range for diatonic scale
    if diatonic_index < 1
        error("not enough notes in scale to go low enough for what's notated")
    end
    if diatonic_index > length(diatonic_scale)
        error("not enough notes in scale to go high enough for what's notated")
    end
    
    % Get the natural frequency
    natural_freq = diatonic_scale(diatonic_index);
    
    % If no accidental, return natural
    if accidental == 0
        freq = natural_freq;
        return;
    end
    
    % Find the closest chromatic index to this frequency
    [~, chromatic_idx] = min(abs(chromatic_scale - natural_freq));
    
    % Apply accidental (sharp = +1 semitone, flat = -1 semitone)
    chromatic_idx = chromatic_idx + accidental;
    
    % Clamp to valid chromatic range
    if chromatic_idx < 1
        error("not enough notes in scale to go low enough for what's notated")
    end
    if chromatic_idx > length(chromatic_scale)
        error("not enough notes in scale to go high enough for what's notated")
    end
    
    freq = chromatic_scale(chromatic_idx);
end


function play_with_blocking(audio_buffer)
    SAMPLE_RATE = 44100;
    % Play with blocking (wait for completion or Ctrl+C)
    fprintf('Playing (press Ctrl+C to stop)...\n');
    player = audioplayer(audio_buffer, SAMPLE_RATE);
    playblocking(player);  % This blocks execution until playback completes
    fprintf('Playback complete.\n');
end


play_notation_music_main();