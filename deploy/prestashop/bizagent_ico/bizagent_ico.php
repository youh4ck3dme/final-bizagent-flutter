<?php
/**
 * BizAgent - Slovenské IČO Autofill
 *
 * @author    BizAgent.sk
 * @copyright 2026 BizAgent.sk
 * @license   Commercial
 */

if (!defined('_PS_VERSION_')) {
    exit;
}

class Bizagent_Ico extends Module
{
    const API_URL = 'https://icoatlas.sk/api/company/proxy-search';
    const CONTRACT_HEADER = 'presta_default';

    public function __construct()
    {
        $this->name = 'bizagent_ico';
        $this->tab = 'billing_invoicing';
        $this->version = '1.0.0';
        $this->author = 'BizAgent.sk';
        $this->need_instance = 0;
        $this->ps_versions_compliancy = array('min' => '1.7', 'max' => _PS_VERSION_);
        $this->bootstrap = true;

        parent::__construct();

        $this->displayName = $this->l('BizAgent - Slovenské IČO Autofill');
        $this->description = $this->l('Automaticky doplní firemné údaje (Názov, Adresa, Mesto) do objednávky na základe IČO. Znižuje chybovosť.');

        $this->confirmUninstall = $this->l('Are you sure you want to uninstall?');
    }

    public function install()
    {
        return parent::install() &&
            $this->registerHook('actionFrontControllerSetMedia') &&
            $this->registerHook('additionalCustomerAddressFields');
    }

    public function uninstall()
    {
        return parent::uninstall();
    }

    /**
     * Add JS/CSS
     */
    public function hookActionFrontControllerSetMedia()
    {
        if ('address' === $this->context->controller->php_self || 'order' === $this->context->controller->php_self) {
            $this->context->controller->registerJavascript(
                'modules-bizagent_ico',
                'modules/' . $this->name . '/views/js/front.js',
                array('position' => 'bottom', 'priority' => 150)
            );

            $this->context->controller->registerStylesheet(
                'modules-bizagent_ico-style',
                'modules/' . $this->name . '/views/css/front.css',
                array('media' => 'all', 'priority' => 150)
            );

            Media::addJsDef(array(
                'bizagent_ajax_url' => $this->context->link->getModuleLink('bizagent_ico', 'ajax', array('ajax' => true))
            ));
        }
    }

    /**
     * Add IČO field to Address Form
     */
    public function hookAdditionalCustomerAddressFields($params)
    {
        $format = new Formatter\AddressFormatter();
        
        // Check if field already exists (some themes/modules add it)
        // But here we enforce our own 'bizagent_ico' virtual field logic 
        // OR we use the standard 'dni' field if adapted? 
        // Let's create a FormField named 'ico'
        
        $formField = (new FormField)
            ->setName('ico') // 'ico' or 'dni'? 'ico' is cleaner if DB supports it or we handle it.
            // CAUTION: PrestaShop default Address model doesn't have 'ico'.
            // Usually 'dni' is used for DPH/IČO or 'company'.
            // For v1 "Simple integration", we want to Autofill EXISTING fields primarily.
            // But if user wants to INPUT IČO, where?
            // "vat_number" exists. "company" exists. "dni" exists.
            
            // Let's input into 'company' or a custom field?
            // Safer: Use 'company' field for name, and enable 'vat_number'.
            // But we need a trigger field.
            
            ->setName('company_ico') // custom dummy field just for lookup?
            ->setType('text')
            ->setLabel($this->l('IČO (Zadajte pre auto-vyplnenie)'))
            ->setRequired(false); // Optional

        // Return array of fields. 
        // Note: Adding a field that doesn't exist in Address ObjectModel might be lost on save 
        // unless we hook into 'actionSubmitCustomerAddressForm' to save it to 'dni' or 'other'.
        
        // BETTER STRATEGY FOR v1:
        // Use standard 'company' field or 'vat_number'. 
        // User inputs IČO into a specialized input that we inject via JS? 
        // No, hookAdditionalCustomerAddressFields behaves natively.
        
        // Let's stick to: We add a field `bizagent_ico_input` which is NOT mapped to DB, just for UI.
        // We assume user wants to fill 'company', 'address1', 'city'.
         
        return array($formField);
    }
}
