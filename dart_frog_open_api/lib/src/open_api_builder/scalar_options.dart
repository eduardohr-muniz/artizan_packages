// ─────────────────────────────────────────────────────────────────────────────
// Supporting types
// ─────────────────────────────────────────────────────────────────────────────

/// Default HTTP client shown in the code-snippet panel.
///
/// [targetKey] examples: `'shell'`, `'node'`, `'python'`, `'ruby'`, `'php'`.
/// [clientKey] examples for shell: `'curl'`, `'httpie'`, `'wget'`.
class ScalarHttpClient {
  const ScalarHttpClient({
    required this.targetKey,
    required this.clientKey,
  });

  /// Language / platform key. E.g. `'shell'`, `'node'`, `'python'`.
  final String targetKey;

  /// Library key within the target. E.g. `'curl'`, `'axios'`, `'requests'`.
  final String clientKey;

  Map<String, dynamic> toJson() => {
        'targetKey': targetKey,
        'clientKey': clientKey,
      };
}

/// HTML `<meta>` and Open Graph tags injected into the Scalar page `<head>`.
class ScalarMetaData {
  const ScalarMetaData({
    this.title,
    this.description,
    this.ogTitle,
    this.ogDescription,
    this.ogImage,
    this.twitterCard,
  });

  final String? title;
  final String? description;
  final String? ogTitle;
  final String? ogDescription;
  final String? ogImage;
  final String? twitterCard;

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (ogTitle != null) 'ogTitle': ogTitle,
        if (ogDescription != null) 'ogDescription': ogDescription,
        if (ogImage != null) 'ogImage': ogImage,
        if (twitterCard != null) 'twitterCard': twitterCard,
      };
}

/// Model Context Protocol integration configuration.
class ScalarMcp {
  const ScalarMcp({
    this.name,
    this.url,
    this.disabled = false,
  });

  final String? name;
  final String? url;
  final bool disabled;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (url != null) 'url': url,
        if (disabled) 'disabled': true,
      };
}

/// Enables path-based routing (e.g. `/docs/users/list`) instead of hash routing.
class ScalarPathRouting {
  const ScalarPathRouting({required this.basePath});

  final String basePath;

  Map<String, dynamic> toJson() => {'basePath': basePath};
}

/// Configures the "Ask AI" agent panel in Scalar.
///
/// On `localhost` Scalar gives 10 free messages without a key.
/// For production you need a Scalar Agent key — get it at
/// https://scalar.com (link your OpenAPI spec to get a key).
///
/// To disable the panel entirely use `ScalarAgent(disabled: true)`.
class ScalarAgent {
  const ScalarAgent({
    this.key,
    this.disabled = false,
  });

  /// Scalar Agent key (not an OpenAI/Anthropic key).
  /// Required for production environments.
  final String? key;

  /// Set to `true` to completely hide the "Ask AI" panel.
  final bool disabled;

  Map<String, dynamic> toJson() => {
        if (key != null) 'key': key,
        if (disabled) 'disabled': true,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Spec environments
// ─────────────────────────────────────────────────────────────────────────────

/// A single variable within a [ScalarEnvironment].
class ScalarEnvironmentVariable {
  const ScalarEnvironmentVariable({
    required this.defaultValue,
    this.description,
  });

  /// Default value shown in Scalar's environment panel (`default` in the spec).
  final String defaultValue;

  /// Optional tooltip shown next to the variable in the environment panel.
  final String? description;

  Map<String, dynamic> toJson() => {
        'default': defaultValue,
        if (description != null) 'description': description,
      };
}

/// A named environment shown in Scalar's environment switcher.
///
/// Variables are available as `{{variableName}}` in any URL, header, query
/// param, or request body inside the "Try it" panel.
///
/// ```dart
/// ScalarEnvironment(
///   name: 'local',
///   description: 'Local development',
///   color: '#00e5c0',
///   variables: {
///     'token': ScalarEnvironmentVariable(defaultValue: '', description: 'JWT from login'),
///     'userId': ScalarEnvironmentVariable(defaultValue: '1'),
///   },
/// )
/// ```
class ScalarEnvironment {
  const ScalarEnvironment({
    required this.name,
    this.description,
    this.color,
    this.variables = const {},
  });

  /// Key used in `x-scalar-environments` and `x-scalar-active-environment`.
  final String name;

  /// Human-readable label shown in the environment switcher.
  final String? description;

  /// Hex accent color (e.g. `'#00e5c0'`).
  final String? color;

  final Map<String, ScalarEnvironmentVariable> variables;

  Map<String, dynamic> toJson() => {
        if (description != null) 'description': description,
        if (color != null) 'color': color,
        'variables': {
          for (final e in variables.entries) e.key: e.value.toJson(),
        },
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Main options class
// ─────────────────────────────────────────────────────────────────────────────

/// Complete configuration for the Scalar API Reference UI.
///
/// All options map 1-to-1 to the official Scalar configuration documented at
/// https://github.com/scalar/scalar/blob/main/documentation/configuration.md
class ScalarOptions {
  const ScalarOptions({
    // ── Appearance ────────────────────────────────────────────────────────────
    this.theme = 'default',
    this.layout = 'modern',
    this.darkMode,
    this.forceDarkModeState,
    this.withDefaultFonts = true,
    this.favicon,
    this.customCss,
    // ── Sidebar & navigation ─────────────────────────────────────────────────
    this.showSidebar = true,
    this.defaultOpenAllTags = false,
    this.defaultOpenFirstTag = true,
    // ── Visibility toggles ────────────────────────────────────────────────────
    this.hideModels = false,
    this.hideSearch = false,
    this.hideDarkModeToggle = false,
    this.hideClientButton = false,
    this.hideTestRequestButton = false,
    this.documentDownloadType = 'both',
    // ── Content display ────────────────────────────────────────────────────────
    this.showOperationId = false,
    this.operationTitleSource = 'summary',
    this.orderRequiredPropertiesFirst = true,
    this.orderSchemaPropertiesBy = 'alpha',
    this.expandAllModelSections = false,
    this.expandAllResponses = false,
    // ── Developer tools ───────────────────────────────────────────────────────
    this.showDeveloperTools = 'localhost',
    this.telemetry = true,
    // ── Request / client ──────────────────────────────────────────────────────
    this.defaultHttpClient,
    this.hiddenClients,
    this.proxyUrl,
    this.baseServerURL,
    this.oauth2RedirectUri,
    this.persistAuth = false,
    // ── Search ────────────────────────────────────────────────────────────────
    this.searchHotKey = 'k',
    // ── Metadata ─────────────────────────────────────────────────────────────
    this.metaData,
    // ── Advanced ─────────────────────────────────────────────────────────────
    this.mcp,
    this.pathRouting,
    this.agent = const ScalarAgent(disabled: true),
  });

  // ── Appearance ──────────────────────────────────────────────────────────────

  /// Color palette. Options: `'default'`, `'alternate'`, `'moon'`, `'purple'`,
  /// `'solarized'`, `'bluePlanet'`, `'saturn'`, `'kepler'`, `'mars'`,
  /// `'deepSpace'`, `'laserwave'`, `'none'`.
  final String theme;

  /// UI layout. `'modern'` (default) or `'classic'`.
  final String layout;

  /// Start in dark mode. When null, Scalar respects the OS preference.
  final bool? darkMode;

  /// Lock the color scheme. `'dark'` or `'light'`.
  final String? forceDarkModeState;

  /// Load Inter and JetBrains Mono from Google Fonts. Set to `false` to use
  /// your own fonts via [customCss]. Defaults to `true`.
  final bool withDefaultFonts;

  /// URL or path to a custom favicon.
  final String? favicon;

  /// Raw CSS injected into the page. Use for branding, logo overrides, or
  /// hiding elements (e.g. `.t-app-bar { display: none !important; }`).
  final String? customCss;

  // ── Sidebar & navigation ────────────────────────────────────────────────────

  /// Show the left navigation sidebar. Defaults to `true`.
  final bool showSidebar;

  /// Start with all tag groups expanded. Defaults to `false`.
  final bool defaultOpenAllTags;

  /// Auto-open the first tag group on load. Defaults to `true`.
  final bool defaultOpenFirstTag;

  // ── Visibility toggles ──────────────────────────────────────────────────────

  /// Hide the Models / Schemas section. Defaults to `false`.
  final bool hideModels;

  /// Hide the search bar. Defaults to `false`.
  final bool hideSearch;

  /// Hide the dark-mode toggle button. Defaults to `false`.
  final bool hideDarkModeToggle;

  /// Hide the "Open in API Client" button. Defaults to `false`.
  final bool hideClientButton;

  /// Hide the "Try it" / Send request button. Defaults to `false`.
  final bool hideTestRequestButton;

  /// Controls the OpenAPI document download button.
  /// Values: `'json'`, `'yaml'`, `'both'` (default), `'direct'`, `'none'`.
  final String documentDownloadType;

  // ── Content display ─────────────────────────────────────────────────────────

  /// Show the `operationId` label next to each endpoint. Defaults to `false`.
  final bool showOperationId;

  /// Source for the endpoint title in the sidebar.
  /// `'summary'` (default) or `'path'`.
  final String operationTitleSource;

  /// List required schema properties before optional ones. Defaults to `true`.
  final bool orderRequiredPropertiesFirst;

  /// Sort schema properties. `'alpha'` (default) or `'preserve'`.
  final String orderSchemaPropertiesBy;

  /// Expand all model/schema accordion sections by default. Defaults to `false`.
  final bool expandAllModelSections;

  /// Expand all response sections by default. Defaults to `false`.
  final bool expandAllResponses;

  // ── Developer tools ─────────────────────────────────────────────────────────

  /// When to show the Developer Tools button.
  /// `'always'`, `'localhost'` (default), or `'never'`.
  final String showDeveloperTools;

  /// Allow Scalar to collect anonymous usage analytics. Defaults to `true`.
  final bool telemetry;

  // ── Request / client ────────────────────────────────────────────────────────

  /// Default language shown in the code-snippet panel.
  /// Example: `ScalarHttpClient(targetKey: 'node', clientKey: 'axios')`.
  final ScalarHttpClient? defaultHttpClient;

  /// Clients to hide from the snippet panel. Pass `true` to hide all,
  /// or a list of `targetKey` strings, e.g. `['ruby', 'php']`.
  final dynamic hiddenClients;

  /// Proxy URL for cross-origin requests made by the "Try it" panel.
  final String? proxyUrl;

  /// Prefix prepended to relative server URLs from the OpenAPI spec.
  final String? baseServerURL;

  /// OAuth 2.0 redirect URI for the authorization code flow.
  final String? oauth2RedirectUri;

  /// Persist the authentication token to `localStorage` across page reloads.
  /// Defaults to `false`.
  final bool persistAuth;

  // ── Search ──────────────────────────────────────────────────────────────────

  /// Keyboard shortcut that opens the search modal (combined with ⌘/Ctrl).
  /// Defaults to `'k'`.
  final String searchHotKey;

  // ── Metadata ────────────────────────────────────────────────────────────────

  /// Page `<title>`, description, and Open Graph / Twitter card tags.
  final ScalarMetaData? metaData;

  // ── Advanced ────────────────────────────────────────────────────────────────

  /// Model Context Protocol integration (AI agent access to your API).
  final ScalarMcp? mcp;

  /// Enable path-based routing instead of hash routing.
  final ScalarPathRouting? pathRouting;

  /// "Ask AI" panel configuration.
  /// Free on localhost (10 messages). Production requires a Scalar Agent key.
  final ScalarAgent? agent;

  // ── Serialization ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      // Appearance
      'theme': theme,
      'layout': layout,
      if (darkMode != null) 'darkMode': darkMode,
      if (forceDarkModeState != null) 'forceDarkModeState': forceDarkModeState,
      'withDefaultFonts': withDefaultFonts,
      if (favicon != null) 'favicon': favicon,
      if (customCss != null) 'customCss': customCss,
      // Sidebar & navigation
      'showSidebar': showSidebar,
      'defaultOpenAllTags': defaultOpenAllTags,
      'defaultOpenFirstTag': defaultOpenFirstTag,
      // Visibility toggles
      'hideModels': hideModels,
      'hideSearch': hideSearch,
      'hideDarkModeToggle': hideDarkModeToggle,
      'hideClientButton': hideClientButton,
      'hideTestRequestButton': hideTestRequestButton,
      'documentDownloadType': documentDownloadType,
      // Content display
      'showOperationId': showOperationId,
      'operationTitleSource': operationTitleSource,
      'orderRequiredPropertiesFirst': orderRequiredPropertiesFirst,
      'orderSchemaPropertiesBy': orderSchemaPropertiesBy,
      'expandAllModelSections': expandAllModelSections,
      'expandAllResponses': expandAllResponses,
      // Developer tools
      'showDeveloperTools': showDeveloperTools,
      'telemetry': telemetry,
      // Request / client
      if (defaultHttpClient != null)
        'defaultHttpClient': defaultHttpClient!.toJson(),
      if (hiddenClients != null) 'hiddenClients': hiddenClients,
      if (proxyUrl != null) 'proxyUrl': proxyUrl,
      if (baseServerURL != null) 'baseServerURL': baseServerURL,
      if (oauth2RedirectUri != null) 'oauth2RedirectUri': oauth2RedirectUri,
      'persistAuth': persistAuth,
      // Search
      'searchHotKey': searchHotKey,
      // Metadata
      if (metaData != null) 'metaData': metaData!.toJson(),
      // Advanced
      if (mcp != null) 'mcp': mcp!.toJson(),
      if (pathRouting != null) '_pathRouting': pathRouting!.toJson(),
      if (agent != null) 'agent': agent!.toJson(),
    };
  }
}
