
module HasKAL.WebUtils.Javascript.Function (
  expandFont,
  getFrameURL
) where


expandFont :: Int -> Int -> String -> String
expandFont defPx shiftPx className = jsFrame defJS body
  where defJS = concat [
          "var x = "++(show defPx)++";",
          "function larger()  {",
            "x += "++(show shiftPx)++";",
            "var y = document.getElementsByClassName('"++(className)++"');",
            "for (var i = 0; i < y.length; i++){",
              "y[i].style.fontSize = x + 'px';",
            "}",
          "}",
          "function smaller()  {",
            "x -= "++(show shiftPx)++";",
            "var y = document.getElementsByClassName('"++(className)++"');",
            "for (var i = 0; i < y.length; i++){",
              "y[i].style.fontSize = x + 'px';",
            "}",
          "}"
          ]
        body = concat [
          "<div>",
          "<span>font size: </span>",
          "<input type=\"submit\" value=\"-\" onclick=\"smaller();\">",
          "<input type=\"submit\" value=\"+\" onclick=\"larger();\">",
          "</div>"
          ]

getFrameURL :: String -> String
getFrameURL frameName = jsFrame defJS body
  where defJS = concat [
          "function alertURL () {",
            "var url = document.location.href;",
            "window.prompt(\"URL of these results. Please, press down Ctrl-c or Cmd-c\",url);",
          "}"
          ]
        body = concat [
          "<div>",
          "<input type=\"submit\" value=\"Get URL\" onclick=\"alertURL();\" style=\"font-size:16px\">",
          "</div>"
          ]

{-- Internal Functions --}
jsFrame :: String -> String -> String
jsFrame defJS body = "<script language=\"Javascript\"><!--\n"++defJS++"\n--></script>"++body
