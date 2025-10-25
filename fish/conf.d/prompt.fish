## My Tide prompt preset (Classic, applied once)
## --------------------------------------------
## I like Tide’s Classic style with sharp tails and a clean frame. I apply it once,
## then let Tide remember via universal variables. If you don’t want this to run,
## set this before your first interactive session:
##   set -U tide_ultrapro_classic_skip 1

if status is-interactive
    if functions -q tide
    # Apply only once per host/user unless I explicitly skip it
        if not set -q tide_ultrapro_classic_applied
            if not set -q tide_ultrapro_classic_skip
                # Configure Tide non-interactively with the options I prefer
                tide configure --auto \
                    --style=Classic \
                    --prompt_colors='True color' \
                    --classic_prompt_color=Dark \
                    --show_time='12-hour format' \
                    --classic_prompt_separators=Round \
                    --powerline_prompt_heads=Round \
                    --powerline_prompt_tails=Sharp \
                    --powerline_prompt_style='Two lines, character and frame' \
                    --prompt_connection=Solid \
                    --powerline_right_prompt_frame=No \
                    --prompt_connection_andor_frame_color=Darkest \
                    --prompt_spacing=Sparse \
                    --icons='Many icons' \
                    --transient=No

                and set -U tide_ultrapro_classic_applied 1
                # Reload Tide so the prompt updates immediately
                tide reload 2>/dev/null
            end
        end
    end
end
