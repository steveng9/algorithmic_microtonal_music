addpath("sounds/");

% score_file = "scores/Xenakis_SixChansons.txt";
score_file = "scores/HeathersSong.txt";
% score_file = "scores/first_text_music.txt";

microtonal.notation.format_score(score_file);
buf = microtonal.notation.notation_to_audio(score_file);
microtonal.audio.play('xenakis_piano', buf);