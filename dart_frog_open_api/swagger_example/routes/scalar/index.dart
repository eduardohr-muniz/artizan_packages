import 'dart:async';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_open_api/dart_frog_open_api.dart';
import '../../main.dart';

FutureOr<Response> onRequest(RequestContext context) => openApi.scalarUiHandler(options: _scalarOptions)(context);

const _scalarOptions = ScalarOptions(
  // ── Appearance ─────────────────────────────────────────────────────────────
  // Options: default, alternate, moon, purple, solarized, bluePlanet,
  //          saturn, kepler, mars, deepSpace, laserwave, none
  theme: 'default',
  layout: 'modern',
  forceDarkModeState: 'dark',
  withDefaultFonts: true,

  // ── Sidebar ────────────────────────────────────────────────────────────────
  showSidebar: true,
  defaultOpenAllTags: false, // true = todas as tags abertas ao carregar
  defaultOpenFirstTag: true,

  // ── Visibilidade ───────────────────────────────────────────────────────────
  hideModels: false, // true = esconde seção Models no rodapé
  hideSearch: false, // true = esconde barra de busca
  hideDarkModeToggle: true, // esconde o botão de toggle dark/light
  hideClientButton: true, // esconde "Open in API Client"
  hideTestRequestButton: false,
  showDeveloperTools: 'never',
  documentDownloadType: 'json', // 'json' | 'yaml' | 'both' | 'direct' | 'none'

  // ── Conteúdo ───────────────────────────────────────────────────────────────
  showOperationId: false,
  operationTitleSource: 'summary',
  orderRequiredPropertiesFirst: true,
  orderSchemaPropertiesBy: 'alpha',
  expandAllModelSections: false,
  expandAllResponses: true, // expande todas as respostas por padrão

  // ── Snippets ───────────────────────────────────────────────────────────────
  // targetKey: shell | node | python | ruby | php | ...
  // clientKey (shell): curl | httpie | wget
  // clientKey (node):  axios | fetch | undici | ky
  defaultHttpClient: ScalarHttpClient(targetKey: 'node', clientKey: 'fetch'),
  // hiddenClients: ['ruby', 'php'],  // esconde tabs específicas

  // ── Rede ───────────────────────────────────────────────────────────────────
  persistAuth: true, // salva o token entre reloads (localStorage)
  // proxyUrl: 'https://proxy.scalar.com',

  // ── Busca ──────────────────────────────────────────────────────────────────
  searchHotKey: 'k',

  // ── Analytics ──────────────────────────────────────────────────────────────
  telemetry: false,

  // ── Metadata ───────────────────────────────────────────────────────────────
  metaData: ScalarMetaData(
    title: 'API Docs — Swagger Example',
    description: 'Dart Frog + Zto DTO annotations demo.',
    ogTitle: 'Swagger Example API',
    ogDescription: 'Interactive API reference powered by Scalar.',
  ),

  // ── MCP ────────────────────────────────────────────────────────────────────
  // disabled: true esconde o botão "Generate MCP" do sidebar.
  // Para habilitar: forneça name + url de um servidor MCP real.
  mcp: ScalarMcp(disabled: true),

  // ── Ask AI ─────────────────────────────────────────────────────────────────
  // Desabilitado por padrão. Para habilitar, forneça uma Scalar Agent key
  // obtida em https://scalar.com (requer vincular o spec na plataforma deles).
  // agent: ScalarAgent(key: 'SUA_SCALAR_AGENT_KEY'),

  // ── Custom CSS ──────────────────────────────────────────────────────────────
  // customCss: '''
  //   .t-app-bar { display: none !important; }

  //   .sidebar-header {
  //     padding-bottom: 12px;
  //   }
  //   .sidebar-header::before {
  //     content: '';
  //     display: block;
  //     width: 100%;
  //     height: 48px;
  //     background-image: url('https://upload.wikimedia.org/wikipedia/commons/e/e0/Google_Dart-logo.svg');
  //     background-size: contain;
  //     background-repeat: no-repeat;
  //     background-position: left center;
  //     margin-bottom: 24px;
  //   }
  // ''',
);
