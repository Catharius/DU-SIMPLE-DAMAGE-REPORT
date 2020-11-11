-- damage report
if core == nil and #screen_list>=1 then
    screen_list[1].setHTML([[<div class="bootstrap" style="font-size:6.045804vw; ">Core not found, please link the board to your core and restart</div>]])
else
    damage_html=dmgrep:renderHTML()
    i = dmgrep:getActiveView()
    if #screen_list == 1 then
        -- If only one screen show top damage and allow view switch 
        screen_list[1].setHTML(damage_html[i])
    elseif #screen_list == 2 then
        -- Show top and listing, still allow view switch
        screen_list[1].setHTML(damage_html[i])
        screen_list[2].setHTML(damage_html[4])
    elseif #screen_list == 3 then    
        -- Show top , front and listing, no more view switch
        screen_list[1].setHTML(damage_html[1])
        screen_list[2].setHTML(damage_html[2])
        screen_list[3].setHTML(damage_html[4])
    elseif #screen_list == 4 then
        -- Show top , front, side and listing, no more view switch
        screen_list[1].setHTML(damage_html[1])
        screen_list[2].setHTML(damage_html[2])
        screen_list[3].setHTML(damage_html[3])
        screen_list[4].setHTML(damage_html[4])
    end
end
