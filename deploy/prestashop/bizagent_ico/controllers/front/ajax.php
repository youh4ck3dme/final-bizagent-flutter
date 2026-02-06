<?php
/**
 * BizAgent Ajax Controller
 */

class Bizagent_IcoAjaxModuleFrontController extends ModuleFrontController
{
    public function initContent()
    {
        parent::initContent();
        $this->ajax = true;
    }

    public function displayAjax()
    {
        $ico = Tools::getValue('ico');
        
        // Basic validation
        if (!$ico || strlen($ico) < 6) {
            die(json_encode(array('found' => false, 'message' => 'Invalid ICO')));
        }

        $apiUrl = 'https://icoatlas.sk/api/company/proxy-search?ico=' . urlencode($ico);
        $header = 'presta_default'; // Segregated Contract v1.1

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $apiUrl);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 10);
        curl_setopt($ch, CURLOPT_HTTPHEADER, array(
            'X-ICO-LOOKUP-CONTRACT: ' . $header,
            'User-Agent: BizAgent-PS-Module/1.0.0'
        ));

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode === 200 && $response) {
            // Passthrough the API response (Expected: {found: true, data: {...}})
            // PS AJAX expects explicit output
            die($response);
        } elseif ($httpCode === 403) {
             die(json_encode(array('found' => false, 'error' => 'Auth failed (403)')));
        } else {
             die(json_encode(array('found' => false, 'error' => 'Server error ' . $httpCode)));
        }
    }
}
