addpath('sounds');

% Random music generator
rng('shuffle');  % Random seed

%% Configuration
num_voices = 4;
num_measures = 12;
standard_measure_length = 6;  % eighth notes
key = 'C major';
tempo = 60;

%% Generate random music
fprintf('Generating random music...\n');

% Create file header
notation = sprintf('Random Composition\n(2026)\ntranscribed by Algorithm\n\n');
notation = sprintf('%sqrt_note = %d\n%s\n[\n', notation, tempo, key);

% Generate measures
for m = 1:num_measures
    % Vary measure length occasionally
    if rand() < 0.7
        measure_length = standard_measure_length;
    else
        measure_length = randi([4, 8]);  % 4-8 eighth notes
    end
    
    % Generate each voice for this measure
    for v = 1:num_voices
        notation = sprintf('%s    [', notation);
        
        remaining = measure_length;
        notes = [];
        
        while remaining > 0
            % Occasionally add a rest
            if rand() < 0.15 && remaining >= 2
                duration = min(randi([1, 3]), remaining);
                notes = [notes, sprintf('r.%d', duration)];
                remaining = remaining - duration;
            else
                % Generate a note
                % Scale degree: mostly stepwise (1-7), occasionally jump
                if rand() < 0.8
                    degree = randi([1, 7]);  % Stepwise
                else
                    degree = randi([-2, 10]);  % Occasional jump
                end
                
                % Occasional accidental
                accidental = '';
                if rand() < 0.1
                    if rand() < 0.5
                        accidental = 's';
                    else
                        accidental = 'f';
                    end
                end
                
                % Random duration (1-4 eighth notes)
                max_dur = min(4, remaining);
                duration = randi([1, max_dur]);
                
                notes = [notes, sprintf('%d%s.%d', degree, accidental, duration)];
                remaining = remaining - duration;
            end
        end
        
        % Join notes with commas
        % Convert the char array to a cell array of character vectors
        newNotes = cellstr(notes);
        result = strjoin(newNotes, ', ')
        
        % OR convert to string array
        newNotesStr = string(notes);
        result = strjoin(newNotesStr, ', ')
        notation = sprintf('%s%s]', notation, result);
        
        if v < num_voices
            notation = sprintf('%s,\n', notation);
        else
            notation = sprintf('%s\n', notation);
        end
    end
end

notation = sprintf('%s]\n', notation);

%% Save to file
filename = 'random_composition.txt';
fid = fopen(filename, 'w');
fprintf(fid, '%s', notation);
fclose(fid);

fprintf('Saved to %s\n', filename);
