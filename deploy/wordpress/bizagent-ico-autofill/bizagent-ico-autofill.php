<?php
/**
 * Plugin Name: BizAgent - Slovenské IČO Autofill
 * Plugin URI:  https://bizagent.sk
 * Description: Automatické doplnenie firemných údajov (ORSR) do WooCommerce pokladne podľa zadaného IČO.
 * Version:     1.0.0
 * Author:      BizAgent.sk
 * Author URI:  https://bizagent.sk
 * License:     GPLv2 or later
 * Text Domain: bizagent-ico
 *
 * @package BizAgent
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit; // Exit if accessed directly.
}

// Define Constants
define( 'BIZAGENT_VERSION', '1.0.0' );
define( 'BIZAGENT_API_URL', 'https://icoatlas.sk/api/company/proxy-search' );
define( 'BIZAGENT_CONTRACT_HEADER', 'wp_default' ); // Segregated Contract v1.1

/**
 * Main Plugin Class
 */
class BizAgent_Ico_Autofill {

	/**
	 * Constructor
	 */
	public function __construct() {
		// Enqueue scripts
		add_action( 'wp_enqueue_scripts', array( $this, 'enqueue_scripts' ) );

		// AJAX handlers (No-priv for checkout)
		add_action( 'wp_ajax_bizagent_lookup_ico', array( $this, 'lookup_ico' ) );
		add_action( 'wp_ajax_nopriv_bizagent_lookup_ico', array( $this, 'lookup_ico' ) );
        
        // Add IČO field to checkout (optional, if using default Woo)
        add_filter( 'woocommerce_checkout_fields' , array( $this, 'add_checkout_fields' ) );
	}

	/**
	 * Enqueue checkout script
	 */
	public function enqueue_scripts() {
		if ( ! is_checkout() ) {
			return;
		}

		wp_enqueue_script( 
			'bizagent-autofill', 
			plugin_dir_url( __FILE__ ) . 'assets/js/bizagent-autofill.js', 
			array( 'jquery' ), 
			BIZAGENT_VERSION, 
			true 
		);

		wp_localize_script( 'bizagent-autofill', 'bizagent_vars', array(
			'ajax_url' => admin_url( 'admin-ajax.php' ),
			'nonce'    => wp_create_nonce( 'bizagent_lookup_nonce' ),
		));

        wp_enqueue_style(
            'bizagent-frontend',
            plugin_dir_url( __FILE__ ) . 'assets/css/bizagent-frontend.css',
            array(),
            BIZAGENT_VERSION
        );
	}
    
    /**
     * Add standard Slovak company fields if missing
     */
    public function add_checkout_fields( $fields ) {
        // Here we could ensure IČO/DIČ/IČ DPH fields exist
        // For standard SK WooCommerce installs, these often come from plugins like "Kybernaut"
        // If not checking for them, we assume standard naming or add our own.
        // For v1 "Money edition", let's hook into standard identifiers often used in SK.
        
        // Simplified: We assume standard custom fields often used: billing_ico, billing_dic, billing_ic_dph
        // Or we add them if user wants. For now, let's stick to pure logic.
        
        return $fields;
    }

	/**
	 * API Lookup Handler
	 */
	public function lookup_ico() {
		check_ajax_referer( 'bizagent_lookup_nonce', 'nonce' );

		$ico = isset( $_POST['ico'] ) ? sanitize_text_field( $_POST['ico'] ) : '';

		if ( empty( $ico ) ) {
			wp_send_json_error( array( 'message' => 'Chýba IČO' ) );
		}
        
        // Call BizAgent API (icoatlas.sk proxy)
        $api_url = add_query_arg( 'ico', $ico, BIZAGENT_API_URL );
        
        $response = wp_remote_get( $api_url, array(
            'timeout' => 10,
            'headers' => array(
                'X-ICO-LOOKUP-CONTRACT' => BIZAGENT_CONTRACT_HEADER,
                'User-Agent' => 'BizAgent-WP-Plugin/' . BIZAGENT_VERSION . ' (' . get_bloginfo('url') . ')'
            )
        ));

        if ( is_wp_error( $response ) ) {
            wp_send_json_error( array( 'message' => 'Chyba spojenia s registrom.' ) );
        }
        
        $code = wp_remote_retrieve_response_code( $response );
        $body = wp_remote_retrieve_body( $response );
        $data = json_decode( $body, true );
        
        // Handle 403 - Contract violation
        if ( $code === 403 ) {
             // Log error for admin?
             error_log( 'BizAgent API Error 403: Invalid Contract Header or Unauthorized.' );
             wp_send_json_error( array( 'message' => 'Služba dočasne nedostupná (Auth).' ) );
        }
        
        // Handle 429 - Rate limit
        if ( $code === 429 ) {
            wp_send_json_error( array( 'message' => 'Prekročený limit požiadaviek. Skúste neskôr.' ) );
        }

        // Handle Normalized API Response: { found: bool, data: ... }
        if ( isset( $data['found'] ) ) {
            if ( $data['found'] === true && ! empty( $data['data'] ) ) {
                wp_send_json_success( $data['data'] );
            } else {
                wp_send_json_error( array( 'message' => 'Firma s týmto IČO nebola nájdená.' ) );
            }
        } else {
            // Fallback for unexpected format
             wp_send_json_error( array( 'message' => 'Neočakávaná odpoveď servera.' ) );
        }
	}
}

// Initialize
new BizAgent_Ico_Autofill();
