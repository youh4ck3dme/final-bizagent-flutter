/**
 * BizAgent - PrestaShop Frontend Logic
 */
$(document).ready(function() {
    // Input pridaný cez hookAdditionalCustomerAddressFields
    var icoInput = $('input[name="company_ico"]');

    if (icoInput.length > 0) {
        icoInput.on('blur', function() {
            var ico = $(this).val().replace(/\s/g, '');
            if (ico.length < 6) return;

            var $form = icoInput.closest('form');
            icoInput.addClass('bizagent-loading-input');

            $.ajax({
                type: 'POST',
                url: bizagent_ajax_url, // Definované v PHP
                data: {
                    ajax: true,
                    ico: ico
                },
                dataType: 'json',
                success: function(response) {
                    icoInput.removeClass('bizagent-loading-input');
                    
                    if (response.found === true && response.data) {
                        var d = response.data;
                        
                        // Autofill Standard PS Fields
                        // Note: Selectors might vary by theme, but these are standard 1.7+ names
                        $form.find('input[name="company"]').val(d.name).trigger('change');
                        $form.find('input[name="address1"]').val(d.street).trigger('change');
                        $form.find('input[name="city"]').val(d.city).trigger('change');
                        $form.find('input[name="postcode"]').val(d.zip).trigger('change');
                        
                        // VAT Number (if module enables it)
                        if (d.ic_dph) {
                            $form.find('input[name="vat_number"]').val(d.ic_dph).trigger('change');
                        }
                        
                        // DNI (often used for DIC or ICO in some countries)
                        // Ak existuje field pre DIČ
                        if (d.dic) {
                             $form.find('input[name="dni"]').val(d.dic).trigger('change');
                        }
                        
                        // Visual success
                        icoInput.addClass('bizagent-success');
                        setTimeout(function(){ icoInput.removeClass('bizagent-success'); }, 2000);
                        
                    } else {
                        console.log('BizAgent: ' + (response.error || response.message));
                    }
                },
                error: function() {
                    icoInput.removeClass('bizagent-loading-input');
                }
            });
        });
    }
});
