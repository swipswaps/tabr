globalVariables(c(".data", ":="))

#' tabr: Music notation syntax, manipulation, analysis and transcription in R.
#'
#' The \code{tabr} package provides a music notation syntax and a collection of
#' music programming functions for generating, manipulating, organizing and
#' analyzing musical information in R.
#'
#' The music notation framework facilitates creating and analyzing music data in
#'  notation form.
#' Music data can be viewed, manipulated and analyzed while in different
#' forms of representation based around different data structures: strings and
#' data frames.
#' Each representation offers advantages over the other for different use cases.
#' Music syntax can be entered directly and represented in character strings to
#' minimize the formatting overhead of data entry by using simple data
#' structures, for example when wanting to quickly enter and transcribe short
#' pieces of music to sheet music or tablature.
#' The package contains functions for directly performing various mathematical,
#' logical and organizational operations and musical transformations on special
#' object classes that facilitate working with music data and notation.
#' The same music data can also be organized in tidy data frames, allowing for
#' a more familiar and powerful approach to the analysis of large amounts of
#' structured music data.
#' Functions are available for mapping seamlessly between these data structures
#' and their representations of musical information.

#' The package also provides API wrapper functions for transcribing musical
#' representations in R into guitar tablature ("tabs") and basic sheet music
#' using the LilyPond backend <http://lilypond.org>.
#'
#' LilyPond is an open source music engraving program for generating high
#' quality sheet music based on markup syntax.
#' The package generates LilyPond files from R code and can pass them to
#' LilyPond to be rendered into sheet music pdf files.
#'
#' While LilyPond caters to sheet music in general and \code{tabr} can be used
#' to create basic sheet music,
#' the transcription functions focus on leveraging LilyPond specifically for
#' creating quality guitar tablature.
#'
#' The package offers nominal MIDI file output support in conjunction with
#' rendering sheet music.
#' The package can read MIDI files and attempts to structure the MIDI data to
#' integrate as best as possible with the data structures and functionality
#' found throughout the package.
#'
#' \code{tabr} offers a useful but limited LilyPond API and is not intended to
#' access all LilyPond functionality from R,
#' nor is transcription via the API the entire scope of \code{tabr}.
#' If you are only creating sheet music on a case by case basis, write your own
#' LilyPond files manually.
#' There is no need to use \code{tabr} or limit yourself to its existing
#' LilyPond API.
#' If you are generating music notation programmatically,
#' \code{tabr} provides the ability to do so in R and has the added benefit of
#' converting what you write in R code to the LilyPond file format to be
#' rendered as printable guitar tablature.
#'
#' While LilyPond is listed as a system requirement for \code{tabr}, you can
#' use the package for music analysis without installing LilyPond if you do not
#' intend to render tabs.
#'
#' @docType package
#' @name tabr
NULL

#' Pipe operator
#'
#' See \code{magrittr} package for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom magrittr %>%
#' @usage lhs \%>\% rhs
NULL

#' @importFrom dplyr tibble
NULL

.uncollapse <- function(x){
  x <- as.character(x)
  if(length(x) == 1) x <- strsplit(x, " ")[[1]]
  idx <- grep("\\*\\d+", x)
  if(length(idx)){
    f <- function(x){
      x <- strsplit(x, "\\*")[[1]]
      rep(x[1], as.integer(x[2]))
    }
    x <- as.list(x)
    x[idx] <- lapply(x[idx], f)
    unlist(x)
  } else {
    x
  }
}

.split_chords <- function(x){
  if(length(x) > 1) x <- paste(x, collapse = " ")
  strsplit(x, "(?<=.)(?=[a-grs ])", perl = TRUE)[[1]]
}

.infer_types <- function(x){
  list(o = .infer_octave_type(x), a = .infer_accidentals(x))
}

.infer_octave_type <- function(x){
  if(note_has_integer(x) & !note_has_tick(x)) "integer" else "tick"
}

.infer_accidentals <- function(x){
  if(any(note_has_sharp(x)) & !any(note_has_flat(x))) "sharp" else "flat"
}

.infer_time_format <- function(x){
  if(length(as.character(x)) == 1) "space" else "vector"
}

.guess_string_type <- function(x, try_info = TRUE){
  y <- tryCatch(
    as_noteworthy(x),
    error = function(e) NULL
  )
  if(!is.null(y)) return("noteworthy")
  if(try_info){
    y <- tryCatch(
      as_noteinfo(x),
      error = function(e) NULL
    )
    if(!is.null(y)) return("noteinfo")
  }
  y <- tryCatch(
    .check_music_split(x),
    error = function(e) NULL
  )
  if(!is.null(y)){
    "music"
  } else if(try_info){
    stop(paste("Cannot coerce string to any of class",
               "'noteworthy', 'noteinfo', or 'music'."), call. = FALSE)
  } else {
    stop("Cannot coerce string to 'noteworthy' or 'music'.", call. = FALSE)
  }
}

.lp_version <- function(){
  lp <- tabr_options()$lilypond
  if(lp == ""){
    if(Sys.info()[["sysname"]] == "Windows"){
      lp <- "lilypond.exe"
    } else {
      lp <- "lilypond"
    }
  }
  x <- tryCatch(
    system(paste(lp, "--version"), intern = TRUE), error = function(e) ""
  )
  if(!(length(x) == 1 && x != ""))
    x <- paste0("\\version \"", gsub("^GNU LilyPond (.*)", "\\1", x[1]), "\"\n")
  x
}

.check_lilypond <- function(){
  if(.lp_version() == "")
    stop("Cannot find LilyPond installation.", call. = FALSE)
  invisible()
}
