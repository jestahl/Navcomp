--[[
	Hazard Coloring Tab
]]

function navcomp.ui.control:CreateColorsTab ()
	local textSize = string.format ("%dx", math.floor (60*navcomp.ui.hsize+0.5))
	local stormColor = iup.text {value = navcomp.ui.hazardColors [1], font=navcomp.ui.font, size = textSize}
	local stormTestButton = iup.button {title="", bgcolor = navcomp.ui.hazardColors [1]}
	local hostileBotColor = iup.text {value = navcomp.ui.hazardColors [2], size = textSize}
	local hostileBotTestButton = iup.button {title="", bgcolor = navcomp.ui.hazardColors [2]}
	local bothColor = iup.text {value = navcomp.ui.hazardColors [3], size = textSize}
	local bothTestButton = iup.button {title="", bgcolor = navcomp.ui.hazardColors [3]}
	local manualColor = iup.text {value = navcomp.ui.hazardColors [4], size = textSize}
	local manualTestButton = iup.button {title="", bgcolor = navcomp.ui.hazardColors [4]}
	local manualStormColor = iup.text {value = navcomp.ui.hazardColors [5], size = textSize}
	local manualStormTestButton = iup.button {title="", bgcolor = navcomp.ui.hazardColors [5]}
	local manualHostileBotColor = iup.text {value = navcomp.ui.hazardColors [6], size = textSize}
	local manualHostileBotTestButton = iup.button {title="", bgcolor = navcomp.ui.hazardColors [6]}
	local manualBothColor = iup.text {value = navcomp.ui.hazardColors [7], size = textSize}
	local manualBothTestButton = iup.button {title="", bgcolor = navcomp.ui.hazardColors [7]}
	local anchorColor = iup.text {value = navcomp.ui.hazardColors [8], size = textSize}
	local anchorTestButton = iup.button {title="", bgcolor = navcomp.ui.hazardColors [8]}
	
	function stormTestButton.action (self)
		self.bgcolor = stormColor.value
	end
	
	function hostileBotTestButton.action (self)
		self.bgcolor = hostileBotColor.value
	end
	
	function bothTestButton.action (self)
		self.bgcolor = bothColor.value
	end
	
	function manualTestButton.action (self)
		self.bgcolor = manualColor.value
	end
	
	function manualStormTestButton.action (self)
		self.bgcolor = manualStormColor.value
	end
	
	function manualHostileBotTestButton.action (self)
		self.bgcolor = manualHostileBotColor.value
	end
	
	function manualBothTestButton.action (self)
		self.bgcolor = manualBothColor.value
	end
	
	function anchorTestButton.action (self)
		self.bgcolor = anchorColor.value
	end
	
	local colorsTab = iup.pdasubframe_nomargin {
		iup.hbox {
			iup.fill {size = 5},
			iup.vbox {
				iup.fill {size = 15},
				iup.label {title="Hazard Colors", font=navcomp.ui.font},
				iup.hbox {
					iup.label {title = "Storm Color:", font=navcomp.ui.font, fgcolor=navcomp.ui.fgcolor, size=string.format ("%dx", math.floor (125*navcomp.ui.hsize+0.5))},
					iup.fill {size=10},
					stormColor,
					stormTestButton;
				},
				iup.hbox {
					iup.label {title = "Hostile Bot Color:", font=navcomp.ui.font, fgcolor=navcomp.ui.fgcolor, size=string.format ("%dx", math.floor (125*navcomp.ui.hsize+0.5))},
					iup.fill {size=10},
					hostileBotColor,
					hostileBotTestButton;
				},
				iup.hbox {
					iup.label {title = "Storm & Bot Color:", font=navcomp.ui.font, fgcolor=navcomp.ui.fgcolor, size=string.format ("%dx", math.floor (125*navcomp.ui.hsize+0.5))},
					iup.fill {size=10},
					bothColor,
					bothTestButton;
				},
				iup.hbox {
					iup.label {title = "Manual Avoid:", font=navcomp.ui.font, fgcolor=navcomp.ui.fgcolor, size=string.format ("%dx", math.floor (125*navcomp.ui.hsize+0.5))},
					iup.fill {size=10},
					manualColor,
					manualTestButton;
				},
				iup.hbox {
					iup.label {title = "Avoid & Storm Color:", font=navcomp.ui.font, fgcolor=navcomp.ui.fgcolor, size=string.format ("%dx", math.floor (125*navcomp.ui.hsize+0.5))},
					iup.fill {size=10},
					manualStormColor,
					manualStormTestButton;
				},
				iup.hbox {
					iup.label {title = "Avoid & Bot Color:", font=navcomp.ui.font, fgcolor=navcomp.ui.fgcolor, size=string.format ("%dx", math.floor (125*navcomp.ui.hsize+0.5))},
					iup.fill {size=10},
					manualHostileBotColor,
					manualHostileBotTestButton;
				},
				iup.hbox {
					iup.label {title = "Avoid, Storm, Bot Color:", font=navcomp.ui.font, fgcolor=navcomp.ui.fgcolor, size=string.format ("%dx", math.floor (125*navcomp.ui.hsize+0.5))},
					iup.fill {size=10},
					manualBothColor,
					manualBothTestButton;
				},
				iup.hbox {
					iup.label {title = "Anchor Color:", font=navcomp.ui.font, fgcolor=navcomp.ui.fgcolor, size=string.format ("%dx", math.floor (125*navcomp.ui.hsize+0.5))},
					iup.fill {size=10},
					anchorColor,
					anchorTestButton;
				},
				iup.fill {};
				expand = "YES"
			},
			iup.fill {};
			expand = "YES"
		};
		tabtitle="Colors",
		font=navcomp.ui.font,
		expand = "YES"
	}
	
	function colorsTab:Initialize ()
	end
	
	function colorsTab:DoSave ()
		navcomp.ui.hazardColors = {
			stormColor.value,
			hostileBotColor.value,
			bothColor.value,
			manualColor.value,
			manualStormColor.value,
			manualHostileBotColor.value,
			manualBothColor.value,
			anchorColor.value
		}
	end
	
	return colorsTab
end