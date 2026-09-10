/**
 * Matterhorn tracker
 *
 * Coleta eventos no navegador e envia para o backend do Matterhorn no Cloud
 * Run, que grava cada um como uma linha no BigQuery.
 *
 * Instalação: ajuste o ENDPOINT abaixo e carregue este arquivo no site (ou
 * cole o conteúdo, dentro de <script>, numa tag de HTML personalizado do
 * Google Tag Manager). Ao carregar, o script já registra um page_view.
 *
 * Eventos personalizados:
 *
 *   matterhorn_event("add_to_cart", { item_id: "SKU-123", price: 49.9 });
 *
 * Escrito em ES5 de propósito, para rodar em qualquer navegador e no GTM sem
 * etapa de build.
 */
(function (window, document, navigator) {
  "use strict";

  // URL de coleta, com /mhc no final. Depois do terraform apply ela aparece
  // no output collector_endpoint.
  var ENDPOINT = "https://matterhorn-backend-NUMERO_DO_PROJETO.us-central1.run.app/mhc";

  // Com true, cada envio aparece no console do navegador.
  var DEBUG = false;

  // A ordem dos testes importa. Samsung Internet, Edge, Opera, Yandex e UC
  // Browser também trazem "Chrome" no user agent, e o Chrome traz "Safari".
  // Por isso os mais específicos vêm primeiro.
  function detectarNavegador(ua) {
    if (/SamsungBrowser/.test(ua)) return "Samsung Internet";
    if (/Edg(e|A|iOS)?\//.test(ua)) return "Microsoft Edge";
    if (/OPR\/|Opera/.test(ua)) return "Opera";
    if (/YaBrowser/.test(ua)) return "Yandex Browser";
    if (/UCBrowser/.test(ua)) return "UC Browser";
    if (/Firefox|FxiOS/.test(ua)) return "Mozilla Firefox";
    if (/MSIE|Trident\//.test(ua)) return "Internet Explorer";
    if (/Chrome|CriOS/.test(ua)) return "Google Chrome";
    if (/Safari/.test(ua)) return "Safari";
    return "(other)";
  }

  function detectarDispositivo(ua, platform) {
    if (/SmartTV|SMART-TV/i.test(ua)) return "Smart TV";

    // Tablet vem antes de celular porque o iPad também anuncia "Mobile".
    // Tablets Android não anunciam, e é assim que se diferenciam do celular.
    if (/Tablet|iPad/i.test(ua) || (/Android/i.test(ua) && !/Mobi/i.test(ua))) {
      return "Tablet";
    }

    // Do iPadOS 13 em diante o iPad se apresenta como Mac. A tela de toque
    // é o que denuncia.
    if (platform === "MacIntel" && navigator.maxTouchPoints > 1) return "Tablet";

    if (/Mobi/i.test(ua)) return "Mobile";
    if (/Win32|Win64|MacIntel|Linux x86_64/i.test(platform)) return "Desktop";
    return "(other)";
  }

  // Calculados uma vez por carregamento de página.
  var navegador = detectarNavegador(navigator.userAgent);
  var dispositivo = detectarDispositivo(navigator.userAgent, navigator.platform);

  function enviar(evento) {
    var xhr = new XMLHttpRequest();
    xhr.open("POST", ENDPOINT, true);
    xhr.setRequestHeader("Content-Type", "application/json");

    if (DEBUG) {
      console.log("[matterhorn] enviando", evento);
      xhr.onreadystatechange = function () {
        if (xhr.readyState !== XMLHttpRequest.DONE) return;
        if (xhr.status >= 200 && xhr.status < 300) {
          console.log("[matterhorn] gravado:", evento.event_name);
        } else {
          // Status 0 quase sempre é CORS, bloqueador de anúncios ou rede.
          console.warn("[matterhorn] falhou:", evento.event_name, "status", xhr.status);
        }
      };
    }

    xhr.send(JSON.stringify(evento));
  }

  /**
   * Registra um evento com o contexto da página atual.
   *
   * @param {string} nome    Nome do evento em snake_case, como "page_view".
   * @param {Object} params  Parâmetros livres. Viram event_params no BigQuery,
   *                         com o valor na coluna do tipo correspondente.
   */
  function matterhorn_event(nome, params) {
    enviar({
      application_type: "web",
      url: window.location.href,
      hostname: window.location.hostname,
      page_title: document.title,
      timestamp: new Date().getTime(), // epoch em ms, pelo relógio do visitante
      os: navigator.platform,
      browser: navegador,
      device: dispositivo,
      language: navigator.language,
      event_name: nome,
      event_params: params || {}
    });
  }

  // Única função exposta para o site. O resto fica dentro desta closure para
  // não colidir com variáveis da página.
  window.matterhorn_event = matterhorn_event;

  matterhorn_event("page_view", {});
})(window, document, navigator);
