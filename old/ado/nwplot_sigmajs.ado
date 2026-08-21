capture program drop nwplotjs
program nwplotjs
	syntax [anything(name = netname)] [, lab labelfactor(real 1)  export edgefactor(real 1) nodefactor(real 1) arrowfactor(real 1) arcstyle(string) replace color(string) edgecolor(string) edgesize(string) linkurious(string) label(string) size(string) fname(string)]
	 
	 
	if "`linkurious'" == "" {
		local linkurious = "http://nwcommands.org/linkurious/"
	}
	
	local arrowfactor = `arrowfactor' * 8
	if "`arcstyle'" == "" {
		local arcstyle = "automatic"
	}
	local netname2 `netname'
	
	local 0 "`label'"
	syntax [varlist(default=none max=1)], [labelfactor(real 1) labelsize(string) labelthreshold(real 1) labelcolor(string) labelcolormode(string) font(string) labelsizeratio(real 1)]
	local label "`varlist'"
	local defaultlabelsize = int(`labelfactor' * 14)
	if "`labelsize'" == "" {
		local labelsize = "fixed"
	}
	_opts_oneof "fixed proportional" "labelsize" "`labelsize'" 6556
	
	if "`labelcolormode'" == "" {
		local labelcolormode = "default"
	}
	_opts_oneof "default node" "labelcolormode" "`labelcolormode'" 6556
	
	if "`font'" == "" {
		local font = "arial"
	}
	
	local 0 = "`size'"
	syntax [varlist(default=none max=1)] , [ minnodesize(real 1.0) maxnodesize(real 5)]
	if "`varlist'" != "" {
		local maxnodesize = `maxnodesize' * 2.5
	}
	local maxnodesize = `maxnodesize' * `nodefactor'
	tempvar s
	gen `s' = 1
	capture replace `s' = `varlist'

	local 0 = "`color'"
	syntax [varlist(default=none max=1)] , [ colorpalette(string) mlcolor(string)]
	if "`colorpalette'" == "" {
		local colorpalette = "#C70039 #0000ff #009933 #ffcc00 #ff00ff #33ccff #996633"
	}
	if "`mlcolor'" == "" {
		local mlcolor = word("`colorpalette'", 1)
	}
	tempvar c
	if "`varlist'" == "" {
		gen `c' = "#C70039"
	}
	else {
		tempvar cg 
		egen `cg' = group(`varlist')
		gen `c' = word("`colorpalette'", `cg')
	}
	
	local 0 = "`edgesize'"
	syntax [anything(name=edgesize)], [minedgesize(real 1) maxedgesize(real 2)]
	local maxedgesize = `maxedgesize' * `edgefactor'
	if "`edgesize'" != "" {
		if "`edgesize'" != "`netname'" {
			nw_syntax `edgesize'
			mata: _sizelist = `netobj'->get_edgelist("`directed'"=="true")
		}
	}
	
	local 0 = "`edgecolor'"
	syntax [anything(name=edgecolor)], [edgecolorpalette(string)]
	if "`edgecolorpalette'" == "" {
		local edgecolorpalette = "#C8C8C8 #0033cc #009933 #ffcc00 #ff00ff #33ccff #996633"
	}
	tempname edgecolors
	if "`edgecolor'" != "" {
		nw_syntax `edgecolor'
		mata: _colorlist = `netobj'->get_edgelist("`directed'"=="true")	
		qui nwtabulate `edgecolor', matrow(`edgecolors')
	}
	
	local netname `netname2'
	nw_datasync `netname'
	nw_syntax `netname'
   
	tempvar xcoord
	tempvar ycoord
	tempvar z
	
	gen `z' = _n / `nodes'
	gen `xcoord' = sin(`z' * 2 * _pi)
	gen `ycoord' = cos(`z' * 2 * _pi)
	
   	tempname expfile

	if "`fname'" == "" {
		local fname "`netname'"
	}
	file open `expfile' using "`fname'.html", write `replace'
	nw_syntax `netname'
	
	file write `expfile' `"<script src="`linkurious'/src/sigma.core.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/conrad.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/utils/sigma.utils.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/utils/sigma.polyfills.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/sigma.settings.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/classes/sigma.classes.dispatcher.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/classes/sigma.classes.configurable.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/classes/sigma.classes.graph.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/classes/sigma.classes.camera.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/classes/sigma.classes.quad.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/captors/sigma.captors.mouse.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/captors/sigma.captors.touch.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/sigma.renderers.canvas.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/sigma.renderers.webgl.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/sigma.renderers.svg.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/sigma.renderers.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/webgl/sigma.webgl.nodes.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/webgl/sigma.webgl.nodes.fast.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/webgl/sigma.webgl.edges.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/webgl/sigma.webgl.edges.fast.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/webgl/sigma.webgl.edges.arrow.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.labels.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.hovers.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.nodes.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.edges.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.edges.curve.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.edges.arrow.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.edges.curvedArrow.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.edgehovers.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.edgehovers.curve.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.edgehovers.arrow.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.edgehovers.curvedArrow.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/canvas/sigma.canvas.extremities.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/svg/sigma.svg.utils.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/svg/sigma.svg.nodes.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/svg/sigma.svg.edges.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/svg/sigma.svg.edges.curve.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/svg/sigma.svg.edges.curvedArrow.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/svg/sigma.svg.labels.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/renderers/svg/sigma.svg.hovers.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/middlewares/sigma.middlewares.rescale.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/middlewares/sigma.middlewares.copy.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/misc/sigma.misc.animation.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/misc/sigma.misc.bindEvents.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/misc/sigma.misc.bindDOMEvents.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/src/misc/sigma.misc.drawHovers.js"></script>"' _newline
	
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.plugins.dragNodes/sigma.plugins.dragNodes.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.helpers.graph/sigma.helpers.graph.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.plugins.activeState/sigma.plugins.activeState.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.plugins.select/sigma.plugins.select.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.plugins.keyboard/sigma.plugins.keyboard.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/settings.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.labels.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.hovers.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.nodes.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.nodes.cross.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.nodes.diamond.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.nodes.equilateral.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.nodes.square.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.nodes.star.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edges.def.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edges.curve.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edges.arrow.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edges.curvedArrow.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.renderers.linkurious/canvas/sigma.canvas.edges.autoCurve.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.plugins.animate/sigma.plugins.animate.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.layouts.fruchtermanReingold/sigma.layout.fruchtermanReingold.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.exporters.image/sigma.exporters.image.js"></script>"' _newline
	file write `expfile' `"<script src="`linkurious'/plugins/sigma.exporters.svg/sigma.exporters.svg.js"></script>"'
	file write `expfile' `"<div id="container">"' _newline
	file write `expfile' `"  <style>"' _newline
	file write `expfile' `"    body {"' _newline
    file write `expfile' `"  color: #333;"' _newline
    file write `expfile' `"  font-size: 14px;"' _newline
    file write `expfile' `"  font-family: Lato, sans-serif;"' _newline
    file write `expfile' `"}"' _newline
	file write `expfile' `"    #graph-container {"' _newline
	file write `expfile' `"      top: 0;"' _newline
	file write `expfile' `"      bottom: 0;"' _newline
	file write `expfile' `"      left: 0;"' _newline
	file write `expfile' `"      right: 0;"' _newline
	file write `expfile' `"      position: absolute;"' _newline
	file write `expfile' `"    }"' _newline
	file write `expfile' `"    #control-pane {"' _newline
    file write `expfile' `"  top: 10px;"' _newline
    file write `expfile' `"  /*bottom: 10px;*/"' _newline
    file write `expfile' `" right: 10px;"' _newline
    file write `expfile' `"  z-index: 1;"' _newline
    file write `expfile' `"  position: absolute;"' _newline
    file write `expfile' `"  width: 230px;"' _newline
    file write `expfile' `"  background-color: rgb(230, 230, 230);"' _newline
    file write `expfile' `"  box-shadow: 0 2px 6px rgba(0,0,0,0);"' _newline
    file write `expfile' `"}"' _newline
    file write `expfile' `"#control-pane > div {"' _newline
    file write `expfile' `"  margin: 10px;"' _newline
    file write `expfile' `"  overflow-x: auto;"' _newline
    file write `expfile' `"}"' _newline
	
	file write `expfile' `"    input[type=range] {"' _newline
    file write `expfile' `"  width: 160px;"' _newline
    file write `expfile' `"}"' _newline

    file write `expfile' `"#image-container {"' _newline
    file write `expfile' `"  top: 0;"' _newline
    file write `expfile' `"  bottom: 0;"' _newline
    file write `expfile' `"  left: 0;"' _newline
    file write `expfile' `"  right: 0;"' _newline
    file write `expfile' `"  position: absolute;"' _newline
    file write `expfile' `"}"' _newline
	
	file write `expfile' `"  </style>"' _newline
	file write `expfile' `"  <div id="graph-container"></div>"' _newline
	file write `expfile' `" "' _newline
	
	if "`export'" != "" { 	
		file write `expfile' `"<div id="control-pane">"' _newline
		file write `expfile' `"<div>"' _newline
		file write `expfile' `"Width: <span id="width-value">0</span>"' _newline
		file write `expfile' `"   <input id="width" type="range" min="0" max="3000" step="100" value="0"> <br>"' _newline
		file write `expfile' `"</div>"' _newline
		file write `expfile' `"<div>"' _newline
		file write `expfile' `"Background: <input type="text" id="color" value="#FFFFFF" /><br>"' _newline
		file write `expfile' `"</div>"' _newline
		file write `expfile' `"<span class="line"></span>"' _newline
		file write `expfile' `"<div>"' _newline
		file write `expfile' `"  <button id="snapClip-btn">Export as PNG</button>"' _newline
		file write `expfile' `"  <button id="export" type="export">Export as SVG</button>"' _newline
		file write `expfile' `"</div>"' _newline
		file write `expfile' `"<div id="dump" class="hidden"></div>"' _newline
		file write `expfile' `"</div>"' _newline
		file write `expfile' `"</div>"' _newline
	}
	file write `expfile' `"<script>"' _newline
	
	// Helpfer functions
	file write `expfile' `"var _ = {"' _newline
	file write `expfile' `"	$: function (id) {"' _newline
    file write `expfile' `"	return document.getElementById(id);"' _newline
	file write `expfile' `"	}"' _newline
	file write `expfile' `"};"' _newline

	file write `expfile' `"function changeWidthValue() {"' _newline
	file write `expfile' `"    var valof = _.$("width").value;"' _newline
	file write `expfile' `"    _.$('width-value').innerHTML = valof;"' _newline
	file write `expfile' `"}"' _newline
	file write `expfile' `""' _newline
	file write `expfile' `"sigma.classes.graph.addMethod('neighbors', function(nodeId) {"' _newline
    file write `expfile' `"	var k,"' _newline
    file write `expfile' `"	neighbors = {},"' _newline
    file write `expfile' `"	index = this.allNeighborsIndex[nodeId] || {};"' _newline
    file write `expfile' `"	for (k in index)"' _newline
    file write `expfile' `"		neighbors[k] = this.nodesIndex[k];"' _newline
    file write `expfile' `"	return neighbors;"' _newline
	file write `expfile' `"});"' _newline
	file write `expfile' `""' _newline
	file write `expfile' "var g = {nodes: [],edges: []};" _newline
	
	forvalues i = 1/`nodes' {
		mata: st_global("r(onenode)", `netobj'->nodes[`i'])
		file write `expfile' "	g.nodes.push({id: '`r(onenode)''"
		if "`label'"!= "" {
			file write `expfile' ", label: '`=`label'[`i']''"
		}
		else {
			if "`lab'" != "" {
				file write `expfile' ", label: '`r(onenode)''"
			}
		}
		file write `expfile' ", x: '`=`xcoord'[`i']''" 
		file write `expfile' ", y: '`=`ycoord'[`i']''" 
		if ("`size'"!= "") {
			file write `expfile' ", size: '`=`s'[`i']''"
		}
		file write `expfile' ", color: '`=`c'[`i']''"
		file write `expfile' "})" _newline 	
	}
	
	// Generate edge entries
	mata: _elist = `netobj'->get_edgelist(0)
	mata: st_numscalar("r(edges)", rows(_elist))
	
	forvalues i = 1/`r(edges)' {
		mata: st_numscalar("r(use)", strtoreal(_elist[`i', 4]))
		if (`r(use)' == 1) {
			mata: st_global("r(elist1)", _elist[`i',1])
			mata: st_global("r(elist2)", _elist[`i',2])
			mata: st_numscalar("r(elist3)", strtoreal(_elist[`i',3]))
			mata: st_numscalar("r(elist4)", strtoreal(_elist[`i',3]))
			mata: st_numscalar("r(elist5)", strtoreal(_elist[`i',3]))
			if "`edgesize'" != "" & "`edgesize'" != "`netname'" {
				mata: st_numscalar("r(elist4)", (strtoreal(_sizelist[`i',3])) + 1)
			}
			if "`edgecolor'" != "" & "`edgecolor'" != "`netname'" {
				mata: st_numscalar("r(elist5)", strtoreal(_colorlist[`i',3]))
			}
			mata: st_numscalar("r(elist6)", strtoreal(_elist[`i',5]))
			
			if (`r(elist3)' != 0 & `r(elist3)' != .) {
				file write `expfile' "	g.edges.push({"
				file write `expfile' "id: 'e`i''" 
				file write `expfile' ", source: '`r(elist1)''"
				file write `expfile' ", target: '`r(elist2)''"
				
				if "`edgesize'" != "" {
					file write `expfile' ", size: '`r(elist4)''"
				}
				if "`directed'" == "false" {
					file write `expfile' ", type: 'line'"
				}
				if "`directed'" == "true" {
					if "`arcstyle'" == "curved" {
						file write `expfile' ", type: 'curvedArrow'"
					}
					else if "`arcstyle'" == "straight" | "`arcstyle'" == "automatic" {
						file write `expfile' ", type: 'arrow'"
					}
					else if "`arcstyle'" == "both"{
						if (`r(elist3)' != 0 & `r(elist3)' != .)  & (`r(elist6)' != 0 & `r(elist6)' != .){
							file write `expfile' ", type: 'curvedArrow'"
						}
						else {
							file write `expfile' ", type: 'arrow'"
						}
					}
				}
	
				if "`edgecolor'" != "" {
					local emax = rowsof(`edgecolors')
					forvalues j = 1/`emax' {
						if "`r(elist5)'" == strofreal(`edgecolors'[`j',1]) {
							local ecolor = word("`edgecolorpalette'", `j')
							file write `expfile' ", color: '`ecolor''"
						}
					}
				}
				else {
					local ecolor = word("`edgecolorpalette'", 1)
					file write `expfile' ", color: '`ecolor''"
				}
				
				file write `expfile' "})" _newline
			}
		}
	}
	
	// Sigma object
	file write `expfile' "" _newline
	file write `expfile' "sigma.renderers.def = sigma.renderers.canvas;" _newline
	file write `expfile' "" _newline
	file write `expfile' "var s = new sigma({graph: g , container: 'graph-container',renderer: {container: document.getElementById('graph-container'), type: 'canvas'}, " _newline
	file write `expfile' "settings: {edgeLabelSize: 'proportional', minEdgeSize: `minedgesize', maxEdgeSize: `maxedgesize', minArrowSize: `arrowfactor'," _newline
	file write `expfile' "minNodeSize: `minnodesize', maxNodeSize: `maxnodesize', dragNodeStickiness: 0.01, nodeBorderSize: 2," _newline
	
	// Label settings
	
	file write `expfile' "defaultLabelSize: `defaultlabelsize',"
	if "`labelcolor'" != "" {
		file write `expfile' "defaultLabelColor: '`labelcolor'',"
	}
	file write `expfile' "labelColor: '`labelcolormode'',"
	file write `expfile' "labelSize: '`labelsize'',"
	file write `expfile' "labelThreshold: `labelthreshold',"
	file write `expfile' "labelSizeRatio: `labelsizeratio',"
	file write `expfile' "font: '`font'',"
	
	file write `expfile' "enableEdgeHovering: false, edgeHoverHighlightNodes: 'circle', defaultEdgeHoverColor: '#000',edgeHoverExtremities: true, autoCurveRatio: 1 ,autoCurveSortByDirection: true}});" _newline  
	file write `expfile' "" _newline
	file write `expfile' "var frListener = sigma.layouts.fruchtermanReingold.configure(s, {" _newline
	file write `expfile' "	iterations: 500," _newline
	file write `expfile' "	easing: 'quadraticInOut'," _newline
	file write `expfile' "	duration: 800" _newline
	file write `expfile' "});" _newline
	file write `expfile' "" _newline
	file write `expfile' "frListener.bind('start stop interpolate', function(e) {" _newline
	file write `expfile' "	console.log(e.type);" _newline
	file write `expfile' "});" _newline
	file write `expfile' "" _newline
	file write `expfile' "sigma.layouts.fruchtermanReingold.start(s);"
	file write `expfile' "" _newline
	file write `expfile' "var activeState = sigma.plugins.activeState(s);" _newline
	file write `expfile' "var dragListener = sigma.plugins.dragNodes(s, s.renderers[0], activeState);" _newline
	file write `expfile' "var select = sigma.plugins.select(s, activeState);" _newline
	file write `expfile' "var keyboard = sigma.plugins.keyboard(s, s.renderers[0]);" _newline
	file write `expfile' "select.bindKeyboard(keyboard);" _newline
	
	// AutoCurve
	if "`arcstyle'" == "automatic" & "`directed'" != "false" {
		file write `expfile' "sigma.canvas.edges.autoCurve(s);" _newline
	}
	
	// Drag nodes
	file write `expfile' "s.refresh();" _newline
	file write `expfile' `""' _newline
	file write `expfile' "dragListener.bind('startdrag', function(event) {" _newline
	file write `expfile' "  console.log(event);" _newline
	file write `expfile' "});" _newline
	file write `expfile' "dragListener.bind('drag', function(event) {" _newline
	file write `expfile' "  console.log(event);" _newline
	file write `expfile' "});" _newline
	file write `expfile' "dragListener.bind('drop', function(event) {" _newline
	file write `expfile' "  console.log(event);" _newline
	file write `expfile' "});" _newline
	file write `expfile' "dragListener.bind('dragend', function(event) {" _newline
	file write `expfile' "  console.log(event);" _newline
	file write `expfile' "});" _newline

	/*
	// Highlight selected nodes
	      // We first need to save the original colors of our
      // nodes and edges, like this:
    file write `expfile' `" s.graph.nodes().forEach(function(n) {"' _newline
    file write `expfile' `"    n.originalColor = n.color;"' _newline
    file write `expfile' `" });"' _newline
    file write `expfile' `"s.graph.edges().forEach(function(e) {"' _newline
    file write `expfile' `"    e.originalColor = e.color;"' _newline
    file write `expfile' `"});"' _newline

      // When a node is clicked, we check for each node
      // if it is a neighbor of the clicked one. If not,
      // we set its color as grey, and else, it takes its
      // original color.
      // We do the same for the edges, and we only keep
      // edges that have both extremities colored.
    file write `expfile' `"s.bind('clickNode', function(e) {"' _newline
    file write `expfile' `"	var nodeId = e.data.node.id,"' _newline
    file write `expfile' `"		toKeep = s.graph.neighbors(nodeId);"' _newline
    file write `expfile' `"		toKeep[nodeId] = e.data.node;"' _newline

    file write `expfile' `"		s.graph.nodes().forEach(function(n) {"' _newline
    file write `expfile' `"		if (toKeep[n.id])"' _newline
    file write `expfile' `"			n.color = n.originalColor;"' _newline
    file write `expfile' `"		else"' _newline
    file write `expfile' `"			n.color = '#eee';"' _newline
    file write `expfile' `"	});"' _newline

    file write `expfile' `"	s.graph.edges().forEach(function(e) {"' _newline
    file write `expfile' `"		if (toKeep[e.source])"' _newline
    file write `expfile' `"			e.color = e.originalColor;"' _newline
    file write `expfile' `"		else"' _newline
    file write `expfile' `"			e.color = '#eee';"' _newline
    file write `expfile' `"	});"' _newline

        // Since the data has been modified, we need to
        // call the refresh method to make the colors
        // update effective.
    file write `expfile' `"	s.refresh();"' _newline
    file write `expfile' `"});"' _newline

      // When the stage is clicked, we just color each
      // node and edge with its original color.
    file write `expfile' `"  s.bind('clickStage', function(e) {"' _newline
    file write `expfile' `"    s.graph.nodes().forEach(function(n) {"' _newline
    file write `expfile' `"      n.color = n.originalColor;});"' _newline

    file write `expfile' `"    s.graph.edges().forEach(function(e) {"' _newline
    file write `expfile' `"      e.color = e.originalColor;});"' _newline

        // Same as in the previous event:
    file write `expfile' `"   s.refresh();"' _newline
    file write `expfile' `"  });"' _newline
*/	
	// Save Image
	file write `expfile' `"function generateImage(mouse, clip) {"' _newline
	file write `expfile' `"	var size = parseInt(_.$("width").value);"' _newline
	file write `expfile' `"	var color = _.$("color").value;"' _newline

	file write `expfile' `"	sigma.plugins.image(s, s.renderers[0], {"' _newline
    file write `expfile' `"		download: true,"' _newline
    file write `expfile' `"		size: size,"' _newline
    file write `expfile' `"		margin: 50,"' _newline
    file write `expfile' `"		background: color,"' _newline
    file write `expfile' `"		clip: clip,"' _newline
    file write `expfile' `"		zoomRatio: 1,"' _newline
    file write `expfile' `"		labels: false"' _newline
	file write `expfile' `"	});"' _newline
	file write `expfile' `"}"' _newline

	file write `expfile' `"_.$('width').addEventListener("change", changeWidthValue); "' _newline
	file write `expfile' `"_.$('snapClip-btn').addEventListener("click", function(event) {"' _newline
	file write `expfile' `"generateImage(event, true)"' _newline
	file write `expfile' `"});"' _newline
	
	file write `expfile' `""' _newline
	file write `expfile' `"document.getElementById('export').onclick = function() {"' _newline
	file write `expfile' `"	console.log('exporting...');"' _newline
    file write `expfile' `"	var output = s.toSVG({download: true, filename: '`netname'.svg', size: 1000});"' _newline
	file write `expfile' `"};"' _newline
	file write `expfile' `""' _newline	
	file write `expfile' "</script>"
	
	capture mata: mata drop _elist 
	capture mata: mata drop _sizelist
	capture mata: mata drop _colorlist
	
	local oscmd "open"
	
	if "`c(return)'" == "Windows" {
		local oscmd "start"
	}
	
	shell `oscmd' `fname'.html 
	
end
