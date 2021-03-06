##### CLASSES #####

#' CNV.anno class
#' @description Annotations required for CNV analysis are stored in this class.
#' @return \code{CNV.anno} class.
#' @details This class does not contain any sample data. Use \code{CNV.create_anno} to create.
#' @examples
#' # create object
#' anno <- CNV.create_anno()
#' 
#' # general information
#' anno
#' show(anno)
#' @author Volker Hovestadt \email{conumee@@hovestadt.bio}
#' @export
setClass("CNV.anno", representation(date = "character", args = "list", 
    genome = "data.frame", gap = "GRanges", probes = "GRanges", exclude = "GRanges", 
    detail = "GRanges", bins = "GRanges"))

#' @rdname CNV.anno-class
#' @importFrom methods show
#' @param object \code{CNV.anno} object
#' @export
setMethod("show", "CNV.anno", function(object) {
    cat("CNV annotation object\n")
    cat("   created  : ", object@date, "\n", sep = "")
    cat("  @genome   : ", nrow(object@genome), " chromosomes\n", sep = "")
    cat("  @gap      : ", length(object@gap), " regions\n", sep = "")
    cat("  @probes   : ", length(object@probes), " probes\n", sep = "")
    cat("  @exclude  : ", length(object@exclude), " regions (overlapping ", 
        length(findOverlaps(object@probes, object@exclude)), " probes)\n", 
        sep = "")
    cat("  @detail   : ", length(object@detail), " regions (overlapping ", 
        length(findOverlaps(object@probes, object@detail)), " probes)\n", 
        sep = "")
    cat("  @bins     : ", length(object@bins), " bins (min/avg/max size: ", 
        object@args$bin_minsize/1000, "/", suppressWarnings(round(mean(width(object@bins))/1000, 
            1)), "/", object@args$bin_maxsize/1000, "kb, probes: ", object@args$bin_minprobes, 
        "/", suppressWarnings(round(mean(values(object@bins)$probes), 1)), 
        "/", max(values(object@bins)$probes), ")\n", sep = "")
})


#' CNV.data class
#' @description Intensities of one or multiple samples are stored in this class.
#' @return \code{CNV.data} class.
#' @details Use \code{CNV.load} to create.
#' @examples
#' # create object
#' library(minfiData)
#' data(MsetEx)
#' 
#' d <- CNV.load(MsetEx)
#' 
#' # general information
#' d
#' show(d)
#' 
#' # show or replace sample names
#' names(d)
#' names(d) <- toupper(names(d))
#' 
#' # subset samples
#' d[1:2]
#' @author Volker Hovestadt \email{conumee@@hovestadt.bio}
#' @export
setClass("CNV.data", representation(date = "character", intensity = "data.frame", BAFsnps="data.frame",gender="character"))

#' @rdname CNV.data-class
#' @param object \code{CNV.data} object
setMethod("show", "CNV.data", function(object) {
    cat("CNV data object\n")
    cat("   created   : ", object@date, "\n", sep = "")
    if (length(object@intensity) == 0) {
        cat("  @intensity : unavailable, run CNV.load\n", sep = "")
    } else {
        cat("  @intensity : available (", ncol(object@intensity), " samples, ", 
            nrow(object@intensity), " probes)\n", sep = "")
    }
    if (length(object@BAFsnps) == 0) {
        cat("  @BAFsnps : unavailable, run CNV.load with MethylSet as input\n", sep = "")
    } else {
        cat("  @BAFsnps : available (", nrow(object@BAFsnps), " values)\n", sep = "")
    }
})

#' @rdname CNV.data-class
#' @param x \code{CNV.data} object (defined by \code{Extract} generic).
#' @param i index. \code{logical}, \code{numeric} or \code{character}.
#' @export
setMethod("[", signature(x = "CNV.data"), function(x, i) {
    x@intensity <- x@intensity[, i, drop = FALSE]
    return(x)
})

#' @rdname CNV.data-class
setMethod("names", signature(x = "CNV.data"), function(x) {
    return(colnames(x@intensity))
})

#' @rdname CNV.data-class
#' @param value Replacement names.
setReplaceMethod("names", signature(x = "CNV.data"), function(x, value) {
    if (length(value) == ncol(x@intensity)) {
        colnames(x@intensity) <- value
    } else {
        stop("number of names does not fit number of samples.")
    }
    return(x)
})


#' CNV.analysis class
#' @description CNV analysis data of a single sample is stored in this class
#' @return \code{CNV.analysis} class.
#' @details Use \code{CNV.fit} to create. Modified by \code{CNV.bin}, \code{CNV.detail} and \code{CNV.segment}.
#' @examples
#' # prepare
#' library(minfiData)
#' data(MsetEx)
#' d <- CNV.load(MsetEx)
#' anno <- CNV.create_anno()
#' 
#' # create object
#' x <- CNV.fit(query = d['GroupB_1'], ref = d[c('GroupA_1', 'GroupA_2', 'GroupA_3')], anno)
#' 
#' # modify object
#' x <- CNV.bin(x)
#' x <- CNV.detail(x)
#' x <- CNV.segment(x)
#' 
#' # general information
#' x
#' show(x)
#' 
#' # coefficients of linear regression
#' coef(x)
#' 
#' # show or replace sample name
#' names(x)
#' names(x) <- 'Sample 1'
#' 
#' # output plots
#' CNV.genomeplot(x)
#' CNV.genomeplot(x, chr = 'chr6')
#' #CNV.detailplot(x, name = 'MYCN')
#' #CNV.detailplot_wrap(x)
#' CNV.write(x, what = 'segments')
#' @author Volker Hovestadt \email{conumee@@hovestadt.bio}
#' @export
setClass("CNV.analysis", representation(name = "character", date = "character", 
    anno = "CNV.anno", fit = "list", bin = "list", detail = "list", seg = "list",arms="list",alteration.summary="list", BAFsnps="data.frame",method.baseline.correction="character",gender="character"))

#' @rdname CNV.analysis-class
#' @param object \code{CNV.analysis} object
setMethod("show", "CNV.analysis", function(object) {
    cat("CNV analysis object\n")
    cat("   created   : ", object@date, "\n", sep = "")
    cat("  @name      : ", object@name, "\n", sep = "")
    cat("  @anno      : ", nrow(object@anno@genome), " chromosomes, ", 
        length(object@anno@probes), " probes, ", length(object@anno@bins), 
        " bins\n", sep = "")
    if (length(object@fit) == 0) {
        cat("  @fit       : unavailable, run CNV.fit\n", sep = "")
    } else {
        cat("  @fit       : available (noise: ", round(object@fit$noise, 
            3), ")\n", sep = "")
    }
    if (length(object@bin) == 0) {
        cat("  @bin       : unavailable, run CNV.bin\n", sep = "")
    } else {
        cat("  @bin       : available (shift: ", round(object@bin$shift, 
            3), ")\n", sep = "")
    }
    if (length(object@detail) == 0) {
        cat("  @detail    : unavailable, run CNV.detail\n", sep = "")
    } else {
        cat("  @detail    : available (", length(object@detail$ratio), 
            " regions)\n", sep = "")
    }
    if (length(object@seg) == 0) {
        cat("  @seg       : unavailable, run CNV.segment\n", sep = "")
    } else {
        cat("  @seg       : available (", nrow(object@seg$summary), " segments)\n", 
            sep = "")
    }
    if (length(object@arms) == 0) {
        cat("  @arms      : unavailable, run CNV.evaluation\n", sep = "")
    } else {
        cat("  @arms      : available (", nrow(object@arms$summary), " chromosome arms)\n", 
          sep = "")
    }
    if (length(object@BAFsnps) == 0) {
        cat("  @BAFsnps   : unavailable, run CNV.load with MethylSet as input\n", sep = "")
    } else {
        cat("  @BAFsnps   : available (", nrow(object@BAFsnps), " values)\n", sep = "")
    }
    if (length(object@method.baseline.correction) == 0) {
        cat("  @baseline  : method unavailable, run CNV.adjustbaseline\n", sep = "")
    } else {
        cat("  @baseline  : method available (", object@method.baseline.correction, ")\n", sep = "")
    }
    if (length(object@gender) == 0) {
        cat("  @gender    : unavailable\n", sep = "")
    } else {
        cat("  @gender    : ", object@gender, "\n", sep = "")
    }
})

#' @rdname CNV.analysis-class
#' @export
setMethod("names", signature(x = "CNV.analysis"), function(x) {
    x@name
})

#' @rdname CNV.analysis-class
#' @param x \code{CNV.analysis} object (defined by \code{show} generic).
#' @param value Replacement names.
#' @export
setReplaceMethod("names", signature(x = "CNV.analysis"), function(x, value) {
    if (length(value) == 1) {
        x@name <- value
    } else {
        stop("need exactly one sample name.")
    }
    return(x)
})

#' @rdname CNV.analysis-class
#' @importFrom stats coef
#' @export
setMethod("coef", signature(object = "CNV.analysis"), function(object) {
    object@fit$coef
}) 
