
addpath('sounds');

dur = 6;
num_notes = 50;
track_length = 6;

scale = microtonal.tet_scales(microtonal.note_to_freq("c2"), 12, microtonal.get_mode(12, 'dorian'), 4);

start_times = [0, track_length * rand(1, num_notes-1)];
notes = datasample(scale, num_notes);
durations = dur * ones(1, num_notes);
audio_buffer = microtonal.build_audio_buffer(notes, start_times, durations, @pure_tubey);

microtonal.play("random_dorian", audio_buffer);














