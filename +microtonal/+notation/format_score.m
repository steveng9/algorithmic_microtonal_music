function format_score(filename)
    % FORMAT_SCORE Validate and format a text notation score for readability
    %
    % Reads a score file, validates it, and rewrites it with aligned pipes
    % so that measure boundaries line up across all voices.
    % Comment lines (beginning with #) are preserved in place.
    %
    % Input:
    %   filename: path to a .txt notation file
    %
    % Example:
    %   microtonal.format_score('scores/Xenakis_SixChansons.txt');

    fid = fopen(filename, 'r');
    if fid == -1
        error('Could not open file: %s', filename);
    end
    file_content = fread(fid, '*char')';
    fclose(fid);

    lines = regexp(file_content, '\r?\n', 'split');

    % Collect header lines (title, year, author — everything before voice: lines)
    header_lines = {};
    voice_meta_lines = {};
    idx = 1;

    % Scan for header (non-voice, non-tempo, non-key lines at the top)
    while idx <= length(lines)
        trimmed = strtrim(lines{idx});
        if startsWith(trimmed, 'voice:') || startsWith(trimmed, 'qtr_note')
            break;
        end
        header_lines{end+1} = lines{idx};
        idx = idx + 1;
    end

    % Collect voice: lines (may have blank lines around them)
    while idx <= length(lines)
        trimmed = strtrim(lines{idx});
        if startsWith(trimmed, 'voice:')
            voice_meta_lines{end+1} = trimmed;
            idx = idx + 1;
        elseif isempty(trimmed)
            idx = idx + 1;
        else
            break;
        end
    end

    num_voices = length(voice_meta_lines);
    if num_voices == 0
        error('No voice: lines found in score');
    end

    fprintf('Score has %d voices\n', num_voices);

    % Parse sections: each starts with qtr_note + key, followed by notation
    formatted_sections = {};

    while idx <= length(lines)
        % Skip blank lines
        while idx <= length(lines) && isempty(strtrim(lines{idx}))
            idx = idx + 1;
        end
        if idx > length(lines)
            break;
        end

        % Expect tempo line
        trimmed = strtrim(lines{idx});
        tempo_match = regexp(trimmed, 'qtr_note\s*=\s*\d+', 'once');
        if isempty(tempo_match)
            idx = idx + 1;
            continue;
        end
        tempo_line = trimmed;
        idx = idx + 1;

        % Skip blank lines before key
        while idx <= length(lines) && isempty(strtrim(lines{idx}))
            idx = idx + 1;
        end

        % Key line
        key_line = strtrim(lines{idx});
        idx = idx + 1;

        % Collect notation blocks until next tempo line or EOF.
        % Each block is a struct:
        %   .pre_comments — comment lines that appeared before this block
        %   .lines        — voice notation lines
        % Comment lines are buffered and attached to the next real block.
        % Comments that trail after the last block are saved separately.
        notation_blocks = {};
        current_block   = {};
        pending_comments = {};

        while idx <= length(lines)
            trimmed = strtrim(lines{idx});

            % Stop at the start of the next section
            if ~isempty(regexp(trimmed, 'qtr_note\s*=\s*\d+', 'once'))
                if ~isempty(current_block)
                    notation_blocks{end+1} = make_block(pending_comments, current_block);
                    pending_comments = {};
                end
                break;
            end

            if startsWith(trimmed, '#')
                % Comment line: flush any open block, then buffer the comment
                if ~isempty(current_block)
                    notation_blocks{end+1} = make_block(pending_comments, current_block);
                    current_block    = {};
                    pending_comments = {};
                end
                pending_comments{end+1} = lines{idx};

            elseif isempty(trimmed)
                % Blank line: flush any open block
                if ~isempty(current_block)
                    notation_blocks{end+1} = make_block(pending_comments, current_block);
                    current_block    = {};
                    pending_comments = {};
                end

            else
                current_block{end+1} = trimmed;
            end

            idx = idx + 1;
        end

        % Flush final block
        if ~isempty(current_block)
            notation_blocks{end+1} = make_block(pending_comments, current_block);
            pending_comments = {};
        end
        % Any comments that came after the last block (rare but possible)
        trailing_comments = pending_comments;

        % Validate and format each notation block
        formatted_blocks = {};
        total_measures   = 0;

        for b = 1:length(notation_blocks)
            block_lines = notation_blocks{b}.lines;

            if length(block_lines) ~= num_voices
                error('Block has %d lines but expected %d voices', length(block_lines), num_voices);
            end

            % Split each voice line into measures
            voice_measures       = cell(num_voices, 1);
            num_measures_in_block = -1;

            for v = 1:num_voices
                raw_measures = strsplit(block_lines{v}, '|');
                cleaned = {};
                for m = 1:length(raw_measures)
                    txt = strtrim(raw_measures{m});
                    if isempty(txt), continue; end
                    if txt(end) == ','
                        txt = strtrim(txt(1:end-1));
                    end
                    cleaned{end+1} = txt;
                end
                voice_measures{v} = cleaned;

                if num_measures_in_block == -1
                    num_measures_in_block = length(cleaned);
                elseif length(cleaned) ~= num_measures_in_block
                    error('Voice %d has %d measures but voice 1 has %d in block', ...
                        v, length(cleaned), num_measures_in_block);
                end
            end

            total_measures = total_measures + num_measures_in_block;

            % Find max width for each measure column
            col_widths = zeros(1, num_measures_in_block);
            for m = 1:num_measures_in_block
                for v = 1:num_voices
                    w = length(voice_measures{v}{m});
                    if w > col_widths(m)
                        col_widths(m) = w;
                    end
                end
            end

            % Build formatted lines
            formatted_lines = cell(num_voices, 1);
            for v = 1:num_voices
                parts = cell(1, num_measures_in_block);
                for m = 1:num_measures_in_block
                    txt = voice_measures{v}{m};
                    if m < num_measures_in_block
                        parts{m} = sprintf('%-*s', col_widths(m) + 1, [txt, ',']);
                    else
                        parts{m} = txt;
                    end
                end
                formatted_lines{v} = strjoin(parts, ' | ');
            end

            fb.pre_comments = notation_blocks{b}.pre_comments;
            fb.lines        = formatted_lines;
            formatted_blocks{end+1} = fb;
        end

        fprintf('Section "%s" at %s: %d measures\n', key_line, tempo_line, total_measures);

        % Validate durations across voices
        validate_block_durations(notation_blocks, num_voices);

        % Store this section
        section.tempo_line        = tempo_line;
        section.key_line          = key_line;
        section.blocks            = formatted_blocks;
        section.trailing_comments = trailing_comments;
        formatted_sections{end+1} = section;
    end

    % Write formatted file
    fid = fopen(filename, 'w');
    if fid == -1
        error('Could not write to file: %s', filename);
    end

    % Write header (remove trailing blank lines)
    while ~isempty(header_lines) && isempty(strtrim(header_lines{end}))
        header_lines(end) = [];
    end
    for i = 1:length(header_lines)
        fprintf(fid, '%s\n', header_lines{i});
    end

    % Write voice meta lines
    fprintf(fid, '\n');
    for i = 1:length(voice_meta_lines)
        fprintf(fid, '%s\n', voice_meta_lines{i});
    end

    % Write sections
    for s = 1:length(formatted_sections)
        sec = formatted_sections{s};

        fprintf(fid, '\n%s\n', sec.tempo_line);
        fprintf(fid, '%s\n', sec.key_line);

        for b = 1:length(sec.blocks)
            % Comments that preceded this block
            for c = 1:length(sec.blocks{b}.pre_comments)
                fprintf(fid, '%s\n', sec.blocks{b}.pre_comments{c});
            end
            % Formatted notation block (blank line before it)
            fprintf(fid, '\n');
            for v = 1:num_voices
                fprintf(fid, '%s\n', sec.blocks{b}.lines{v});
            end
        end

        % Any comments after the last block in this section
        for c = 1:length(sec.trailing_comments)
            fprintf(fid, '%s\n', sec.trailing_comments{c});
        end
    end

    fclose(fid);
    fprintf('Formatted and saved: %s\n', filename);
end


function blk = make_block(pre_comments, lines)
    blk.pre_comments = pre_comments;
    blk.lines        = lines;
end


function validate_block_durations(blocks, num_voices)
    measure_idx = 0;
    for b = 1:length(blocks)
        block = blocks{b}.lines;
        raw_measures_v1 = strsplit(block{1}, '|');

        for m = 1:length(raw_measures_v1)
            txt = strtrim(raw_measures_v1{m});
            if isempty(txt), continue; end
            measure_idx = measure_idx + 1;

            dur1 = sum_measure_duration(txt);

            for v = 2:num_voices
                v_measures = strsplit(block{v}, '|');
                if m > length(v_measures), continue; end
                v_txt = strtrim(v_measures{m});
                if isempty(v_txt), continue; end

                dur_v = sum_measure_duration(v_txt);
                if abs(dur_v - dur1) > 0.01
                    fprintf('WARNING: Measure %d - voice 1 has %.1f eighths, voice %d has %.1f eighths\n', ...
                        measure_idx, dur1, v, dur_v);
                end
            end
        end
    end
end


function dur = sum_measure_duration(measure_text)
    if measure_text(end) == ','
        measure_text = measure_text(1:end-1);
    end
    tokens = strsplit(measure_text, ',');
    dur = 0;
    for i = 1:length(tokens)
        tok = strtrim(tokens{i});
        if isempty(tok), continue; end
        parts = strsplit(tok, '.');
        if length(parts) == 2
            dur = dur + str2double(parts{2});
        end
    end
end
