#' @export
#' 
#' @import grid
makeIcon <- function(iconPath, shape = 'circle', fill = sample(colors(), 1)){
  png(iconPath, width = 48, height = 48, units = 'px')
  vp <- viewport(x=0.5,y=0.5,width=1, height=1)
  pushViewport(vp)
  
  if (shape == 'circle'){
    grid.circle(x=0.5, y=0.5, r=0.45, gp = gpar(fill = fill))
  } else {
    grid.rect(x = 0.5, y = 0.5, width = 0.9, height = 0.9, gp = gpar(fill = fill))
  }
  dev.off()
}

#' Get input/output configuration information from a macro
#' 
#' 
#' @export
#' @examples
#'  template <- "~/Desktop/SNIPPETS/dev/Optimization/Supporting_Macros/Optimization.yxmc"
#'  x = getIO(template)
getIO <- function(template){
  library(XML)
  xml <- xmlInternalTreeParse(template)
  r <- xmlRoot(xml)
  g <- getNodeSet(r, '//Question')
  l <- lapply(g, xmlToList)
  getMacroIO <- function(type = 'MacroInput'){
    toolIds = unlist(Filter(Negate(is.null), sapply(l, function(d){
      if (d$Type == type) d$ToolId[['value']]
    })))
    inputs <- lapply(toolIds, function(i){
      query = sprintf('//Node[@ToolID="%s"]//Properties//Configuration', i)
      node = getNodeSet(r, query)
      xmlToList(node[[1]])[c('Name', 'Abbrev')]
    })
    lapply(inputs, function(x){
      if (is.null(x$Abbrev)){
        x$Abbrev = ""
      } else {
        x$Abbrev = gsub("\n|\\s+", "", inputs[[1]]$Abbrev)
      }
      return(x)
    })
  }
  list(
    inputs = getMacroIO('MacroInput'),
    outputs = getMacroIO('MacroOutput'),
    pluginName = tools::file_path_sans_ext(basename(template))
  )
}


#' Make plugin configuration xml file
#' 
#' @export
#' @examples 
#' x = list(
#'   inputs = list(
#'     list(Name = 'Input A', Abbrev = "A"),
#'     list(Name = 'Input B', Abbrev = "B")
#'   ),
#'   outputs = list(
#'     list(Name = 'Output C', Abbrev = "C")
#'   ),
#'   pluginName = 'Foo'
#' )
#' do.call(makePluginConfig, x)
makePluginConfig <- function(inputs, outputs, pluginName, properties = NULL){
  library(XML)
  # Create Config XML
  d = xmlTree()
  d$addNode("AlteryxJavaScriptPlugin", close = FALSE)
  d$addNode("EngineSettings", attrs= list(
    EngineDLL = "Macro",
    EngineDLLEntryPoint = sprintf("Supporting_Macros/%s.yxmc", pluginName),
    SDKVersion = "10.1"
  ))
  d$addNode("GuiSettings", attrs = list(
    Html = sprintf("%sGui.html", pluginName),
    Icon = sprintf("%sIcon.png", pluginName),
    SDKVersion = "10.1"
  ), close = F)
  d$addNode("InputConnections", .children = sapply(inputs, function(x){
    d$addNode("Connection", attrs = list(
      Name = x$Name,
      AllowMultiple = "False",
      Optional = "True",
      Type = "Connection",
      Label = x$Abbrev
    ))
  }))
  d$addNode("OutputConnections", .children = sapply(outputs, function(x){
    d$addNode("Connection", attrs = list(
      Name = x$Name,
      AllowMultiple = "False",
      Optional = "True",
      Type = "Connection",
      Label = x$Abbrev
    ))
  }))
  d$closeNode()
  if (!is.null(properties)){
    d$addNode("Properties", close = F)
    d$addNode("MetaInfo", .children = sapply(names(properties), function(k){
      d$addNode(k, properties[[k]])
    }))
  }
  d$closeNode()
  d$value() 
}