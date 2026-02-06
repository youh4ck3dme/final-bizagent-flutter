<?php
// Test Harness for BizAgent Plugins
// Simulates CMS environment to verify API calls and Logic

// ─── CONFIG ──────────────────────────────────────────────────────────
define('TEST_ICO', '31333532'); // ESET
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "═══════════════════════════════════════════════════════════\n";
echo "  BizAgent Plugins Verification Suite\n";
echo "═══════════════════════════════════════════════════════════\n\n";

// ─── MOCKS ───────────────────────────────────────────────────────────

// WordPress Mocks
if (!function_exists('add_action')) { function add_action($tag, $callback) {} }
if (!function_exists('add_filter')) { function add_filter($tag, $callback) {} }
if (!function_exists('plugin_dir_url')) { function plugin_dir_url($file) { return '/dummy/url/'; } }
if (!function_exists('admin_url')) { function admin_url($path) { return '/admin/' . $path; } }
if (!function_exists('wp_create_nonce')) { function wp_create_nonce($action) { return 'nonce123'; } }
if (!function_exists('check_ajax_referer')) { function check_ajax_referer($action) { return true; } }
if (!function_exists('wp_localize_script')) { function wp_localize_script() {} }
if (!function_exists('wp_enqueue_script')) { function wp_enqueue_script() {} }
if (!function_exists('wp_enqueue_style')) { function wp_enqueue_style() {} }
if (!function_exists('sanitize_text_field')) { function sanitize_text_field($str) { return trim($str); } }
if (!function_exists('is_checkout')) { function is_checkout() { return true; } }
if (!function_exists('get_bloginfo')) { function get_bloginfo() { return 'http://test-harness.local'; } }
if (!function_exists('is_wp_error')) { function is_wp_error($thing) { return false; } }

function wp_send_json_success($data) {
    echo "✅ WP SUCCESS: Found company: " . (isset($data['name']) ? $data['name'] : 'Unknown') . "\n";
    // echo "Data: " . json_encode($data) . "\n";
}
function wp_send_json_error($data) {
    echo "❌ WP ERROR: " . $data['message'] . "\n";
}

// Real HTTP Call Simulation for WordPress
function wp_remote_get($url, $args) {
    echo "   [WP HTTP] GET $url\n";
    echo "   [WP HTTP] Headers: " . json_encode($args['headers']) . "\n";
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, $args['timeout']);
    
    // Convert headers associative array to curl format
    $headers = [];
    foreach ($args['headers'] as $k => $v) {
        $headers[] = "$k: $v";
    }
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    
    $body = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return [
        'response' => ['code' => $code],
        'body' => $body
    ];
}

function wp_remote_retrieve_response_code($response) {
    return $response['response']['code'];
}
function wp_remote_retrieve_body($response) {
    return $response['body'];
}
function add_query_arg($key, $val, $url) {
    return $url . (strpos($url, '?') === false ? '?' : '&') . $key . '=' . $val;
}

// PrestaShop Mocks
class Module {
    public $l_cache = [];
    public function __construct() {}
    public function l($str) { return $str; }
    public function registerHook($name) { return true; }
    public function install() { return true; }
    public function uninstall() { return true; }
}

class FormField {
    public function setName($n) { return $this; }
    public function setType($t) { return $this; }
    public function setLabel($l) { return $this; }
    public function setRequired($r) { return $this; }
}

class Tools {
    public static function getValue($key) {
        if ($key === 'ico') return TEST_ICO;
        return null;
    }
}

class ModuleFrontController {
    public function initContent() {}
}

// Global defines
define('ABSPATH', true);
define('_PS_VERSION_', '1.7.0.0');

// ─── TEST 1: WordPress Plugin ────────────────────────────────────────
echo "TEST 1: WordPress Plugin Logic\n---------------------------------------\n";

// Setup Post Data
$_POST['ico'] = TEST_ICO;

// Load Plugin File
require_once 'deploy/wordpress/bizagent-ico-autofill/bizagent-ico-autofill.php';

// Instantiate and Run
$wp_plugin = new BizAgent_Ico_Autofill();
$wp_plugin->lookup_ico(); // Should print success message

echo "\n";

// ─── TEST 2: PrestaShop Module ───────────────────────────────────────
echo "TEST 2: PrestaShop Module Logic (Ajax Controller)\n---------------------------------------\n";

// Function to simulate 'die' in PrestaShop controller
function mock_die($str) {
    $data = json_decode($str, true);
    if (isset($data['found']) && $data['found'] === true) {
         echo "✅ PS SUCCESS: Found company: " . (isset($data['data']['name']) ? $data['data']['name'] : 'Unknown') . "\n";
    } elseif (isset($data['found']) && $data['found'] === false) {
         echo "❌ PS NORMALIZED: " . (isset($data['error']) ? $data['error'] : 'Unknown') . "\n";
    } else {
         echo "✅ PS RAW RESPONSE: " . substr($str, 0, 100) . "...\n";
    }
}

// Load Ajax Controller
// We need to modify the Include locally or just regex replace 'die(' with 'mock_die(' for testing safely
$ps_ajax_code = file_get_contents('deploy/prestashop/bizagent_ico/controllers/front/ajax.php');
$ps_ajax_code = str_replace('<?php', '', $ps_ajax_code);
$ps_ajax_code = str_replace('die(', 'mock_die(', $ps_ajax_code);
$ps_ajax_code = str_replace('class Bizagent_IcoAjaxModuleFrontController', 'class Bizagent_IcoAjaxModuleFrontController_Test', $ps_ajax_code);

// Eval the modified code to define the class
eval($ps_ajax_code);

$ps_controller = new Bizagent_IcoAjaxModuleFrontController_Test();
$ps_controller->displayAjax();

echo "\n";
