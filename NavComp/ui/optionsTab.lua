--[[
	Options Tab for NavComp control screen
]]

function navcomp.ui.control:CreateOptionsTab ()
	local plotToggle = iup.stationtoggle {title="  Background Plot", fgcolor=navcomp.ui.fgcolor}
	local avoidStormToggle = iup.stationtoggle {title="  Avoid Storm Sectors", fgcolor=navcomp.ui.fgcolor}
	local avoidManualToggle = iup.stationtoggle {title="  Avoid Manual Sectors", fgcolor=navcomp.ui.fgcolor}
	local avoidBlockableToggle = iup.stationtoggle {title="  Avoid Stations and Wormholes as waypoints", fgcolor=navcomp.ui.fgcolor}
	local useSegmentSmoothingToggle = iup.stationtoggle {title="  Use Segment Smoothing", fgcolor=navcomp.ui.fgcolor}
	local anchorOverrideToggle = iup.stationtoggle {title="  Use Fixed Anchors", fgcolor=navcomp.ui.fgcolor}
	local autoPlotToggle = iup.stationtoggle {title="  Force Auto Plot after Path Load", fgcolor=navcomp.ui.fgcolor}
	local plotCapitalSystemsToggle = iup.stationtoggle {title="  Plot Capital Systems", fgcolor=navcomp.ui.fgcolor}
	local blockStatusMessageToggle = iup.stationtoggle {title=" Block Status Messages", fgcolor=navcomp.ui.fgcolor}
	
	local delayText = iup.text {value = tostring (navcomp.data.delay) .. "  ", font=navcomp.ui.font}
	local chunkText = iup.text {value = tostring (navcomp.data.maxStepLimit) .. "  ", font=navcomp.ui.font}
	
	local stormExpireText = iup.text {value = tostring (navcomp.data.stormExpires), font=navcomp.ui.font}
	local botExpireText = iup.text {value = tostring (navcomp.data.botExpires), font=navcomp.ui.font}
	
	local optionsTab = iup.pdasubframe_nomargin {
		iup.hbox {
			iup.fill {size = 5},
			iup.vbox {
				iup.fill {size = 15},
				iup.label {title="Performance Options", font=navcomp.ui.font},
				iup.hbox {
					plotToggle,
					iup.fill {size = 25},
					iup.label {title = "Delay:  ", fgcolor = navcomp.ui.fgcolor, alignment = "ARIGHT", expand = "HORIZONTAL"},
					delayText,
					iup.fill {size = 25};
				},
				iup.hbox {
					avoidStormToggle,
					iup.fill {size = 25},
					iup.label {title = "Chunk Size:  ", fgcolor = navcomp.ui.fgcolor, alignment = "ARIGHT", expand = "HORIZONTAL"},
					chunkText,
					iup.fill {size = 25};
				},
				avoidManualToggle,
				avoidBlockableToggle,
				useSegmentSmoothingToggle,
				plotCapitalSystemsToggle,
				blockStatusMessageToggle,
				iup.fill {size = 15},
				iup.label {title="Load Options", font=navcomp.ui.font},
				autoPlotToggle,
				iup.fill {size = 15},
				iup.label {title="Anchors", font=navcomp.ui.font},
				anchorOverrideToggle,
				iup.fill {size = 15},
				iup.label {title="Data Expiration", font=navcomp.ui.font},
				iup.fill {size = 5},
				iup.hbox {
					iup.fill {size=5},
					iup.label {title="Storm Data (sec): ", font=navcomp.ui.font, fgcolor=navcomp.ui.fgcolor, alignment="ARIGHT"},
					stormExpireText,
					iup.fill {size=25},
					iup.label {title="Bot Data (sec): ", font=navcomp.ui.font, fgcolor=navcomp.ui.fgcolor, alignment="ARIGHT"},
					botExpireText,
					iup.fill {size=25};
				},
				iup.fill {};
				expand = "YES"
			},
			iup.fill {size = 5};
			expand = "YES"
		};
		tabtitle="Options",
		font=navcomp.ui.font,
		expand = "YES"
	}
	
	function optionsTab:Initialize ()
		plotToggle.value = navcomp.ui:GetOnOffSetting (navcomp.data.backgroundPlot)
		avoidStormToggle.value = navcomp.ui:GetOnOffSetting(navcomp.data.avoidStormSectors)
		avoidManualToggle.value = navcomp.ui:GetOnOffSetting (navcomp.data.avoidManualSectors)
		avoidBlockableToggle.value = navcomp.ui:GetOnOffSetting (navcomp.data.avoidBlockableSectors)
		useSegmentSmoothingToggle.value = navcomp.ui:GetOnOffSetting (navcomp.data.useSegmentSmoothing)
		anchorOverrideToggle.value = navcomp.ui:GetOnOffSetting (navcomp.data.anchorOverride)
		autoPlotToggle.value = navcomp.ui:GetOnOffSetting (navcomp.data.autoPlot)
		plotCapitalSystemsToggle.value = navcomp.ui:GetOnOffSetting (navcomp.data.plotCapitalSystems)
		blockStatusMessageToggle.value = navcomp.ui:GetOnOffSetting (navcomp.data.blockStatusMessage)
		
		--[[delayText = iup.text {value = tostring (navcomp.data.delay) .. "  "}
		chunkText = iup.text {value = tostring (navcomp.data.maxStepLimit) .. "  "}
		stormExpireText = iup.text {value = tostring (navcomp.data.stormExpires)}
		botExpireText = iup.text {value = tostring (navcomp.data.botExpires)}]]
		
		delayText.value = tostring (navcomp.data.delay) .. "  "
		chunkText.value = tostring (navcomp.data.maxStepLimit) .. "  "
		stormExpireText.value = tostring (navcomp.data.stormExpires) .. "  "
		botExpireText.value = tostring (navcomp.data.botExpires) .. "  "
	end
	optionsTab:Initialize ()
	
	function optionsTab:DoSave ()
		navcomp.data.backgroundPlot = plotToggle.value == "ON"
		navcomp.data.avoidStormSectors = avoidStormToggle.value == "ON"
		navcomp.data.avoidManualSectors = avoidManualToggle.value == "ON"
		navcomp.data.avoidBlockableSectors = avoidBlockableToggle.value == "ON"
		navcomp.data.useSegmentSmoothing = useSegmentSmoothingToggle.value == "ON"
		navcomp.data.anchorOverride = anchorOverrideToggle.value == "ON"
		navcomp.data.autoPlot = autoPlotToggle.value == "ON"
		navcomp.data.plotCapitalSystems = plotCapitalSystemsToggle.value == "ON"
		navcomp.data.blockStatusMessage = blockStatusMessageToggle.value == "ON"
		navcomp.data.delay = tonumber (delayText.value)
		navcomp.data.maxStepLimit = tonumber (chunkText.value)
		navcomp.data.stormExpires = tonumber (stormExpireText.value)
		navcomp.data.botExpires = tonumber (botExpireText.value)
	end
	
	return optionsTab
end