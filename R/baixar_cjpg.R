#' Baixa julgados de primeiro grau de São Paulo
#'
#' @param livre Busca livre. Usar os mesmos critérios da página.
#' @param aspas Lógico. Coloque TRUE se quiser colocar aspas nas busca livre.
#' @param processo Número do processo unificado. Pode colocar com pontos ou sem pontos.
#' @param foro Número do fórum
#' @param vara Número da vara
#' @param classe Número da classe processual
#' @param assunto Número do assunto
#' @param magistrado Código do magistrado
#' @param inicio Data inicial no formato "dd/mm/aaa"
#' @param fim  Data final no formato "dd/mm/aaaa" O lapso entre essas duas datas não deve passar de um ano.
#' @param diretorio Diretório onde serão armazenados os htmls.
#' @param paginas Páginas a serem baixadas
#' @return Baixa os htmls com metadados das decisãoes de primeiro grau.
#' @export
#'
#' @examples
#' \dontrun{
#' baixar_cjpg("homicídio simples")
#' }
#'
baixar_cjpg<-function (livre = "", aspas = FALSE, processo = "", foro = "",
                       vara = "", classe = "", assunto = "", magistrado = "", inicio = "",
                       fim = "", diretorio = ".",paginas=NULL)
{
  if (aspas == TRUE) {
    livre <- deparse(livre)
  }
  httr::set_config(httr::config(ssl_verifypeer = FALSE))
  if (processo != "") {
    processo <- processo %>% stringr::str_remove_all("\\D+") %>%
      stringr::str_pad(width = 20, "left", "0") %>% abjutils::build_id()
    unificado <- stringr::str_extract(processo, ".+?(?=\\.8\\.26)")
  }
  else {
    unificado <- ""
  }
  if (foro == "" && processo != "") {
    foro <- stringr::str_extract(processo, "\\d{4}$")
  }
  classe <- paste0(classe, collapse = ",")
  assunto <- paste0(assunto, collapse = ",")
  magistrado <- paste0(magistrado, collapse = ",")
  if (magistrado != "") {
    maiorAgente <- "2"
  }
  else {
    maiorAgente <- "0"
  }
  url_parseada <- list(scheme = "http", hostname = "esaj.tjsp.jus.br",
                       port = NULL, path = "cjpg/pesquisar.do", query = list(conversationId = "",
                                                                             dadosConsulta.pesquisaLivre = livre, tipoNumero = "UNIFICADO",
                                                                             numeroDigitoAnoUnificado = unificado, foroNumeroUnificado = foro,
                                                                             dadosConsulta.nuProcesso = processo, dadosConsulta.nuProcessoAntigo = "",
                                                                             classeTreeSelection.values = classe, classeTreeSelection.text = "",
                                                                             assuntoTreeSelection.values = assunto, assuntoTreeSelection.text = "",
                                                                             agenteSelectedEntitiesList = "", contadoragente = "0",
                                                                             contadorMaioragente = maiorAgente, cdAgente = "",
                                                                             nmAgente = "", `dadosConsulta.agentes[0].cdAgente` = magistrado,
                                                                             `dadosConsulta.agentes[0].nmAgente` = "", dadosConsulta.dtInicio = inicio,
                                                                             dadosConsulta.dtFim = fim, varasTreeSelection.values = vara,
                                                                             varasTreeSelection.text = "", dadosConsulta.ordenacao = "DESC"))
  if (magistrado == "") {
    url_parseada$query$`dadosConsulta.agentes[0].cdAgente` <- NULL
    url_parseada$query$`dadosConsulta.agentes[0].nmAgente` <- NULL
  }
  class(url_parseada) <- "url"
  url <- httr::build_url(url_parseada)
  resposta <- httr::RETRY("GET",url=url,times=5,timeout=30,quiet=TRUE)

  if (is.null(paginas)) {
    p <- resposta %>% httr::content() %>% xml2::xml_find_first(xpath = "//*[@bgcolor='#EEEEEE']") %>%
      xml2::xml_text(trim = T) %>% stringr::str_extract("\\d+$") %>%
      as.numeric()
    max_pag <- ceiling(p/10)

    paginas<-1:max_pag
  }
  purrr::walk(paginas, purrr::possibly(~{
    httr::RETRY("GET",url=paste0("http://esaj.tjsp.jus.br/cjpg/trocarDePagina.do?pagina=",
                                 .x, "&conversationId="), quiet=TRUE, httr::set_cookies(unlist(resposta$cookies)),
                httr::write_disk(paste0(diretorio,"/",stringr::str_replace_all(Sys.time(),"\\D","_"), "_pagina_", .x,
                                        ".html"), overwrite = T),timeout=30,times=5)
  }, otherwise = NULL))
}
