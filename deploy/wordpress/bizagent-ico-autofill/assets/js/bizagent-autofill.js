jQuery(document).ready(function($) {
    var icoField = $('#billing_ico');
    
    // Ak IČO field neexistuje, skúsime iné bežné ID alebo nič
    if (icoField.length === 0) {
        icoField = $('input[name="billing_ico"]');
    }

    if (icoField.length > 0) {
        icoField.on('blur', function() {
            var ico = $(this).val().replace(/\s/g, '');
            
            // Validácia dĺžky (8 číslic pre SK)
            if (ico.length < 6) return;

            // Visual feedback - loading
            var container = icoField.closest('.form-row');
            container.addClass('bizagent-loading');
            icoField.prop('disabled', true);

            $.ajax({
                url: bizagent_vars.ajax_url,
                type: 'POST',
                data: {
                    action: 'bizagent_lookup_ico',
                    ico: ico,
                    nonce: bizagent_vars.nonce
                },
                success: function(response) {
                    icoField.prop('disabled', false);
                    container.removeClass('bizagent-loading');

                    if (response.success) {
                        var data = response.data;
                        
                        // Autofill logic
                        if (data.name) $('#billing_company').val(data.name).trigger('change');
                        if (data.street) $('#billing_address_1').val(data.street).trigger('change');
                        if (data.city) $('#billing_city').val(data.city).trigger('change');
                        if (data.zip) $('#billing_postcode').val(data.zip).trigger('change');
                        
                        // Extra fields (DIC, IC DPH) - ak existujú vo formulári
                        if (data.dic && $('#billing_dic').length) {
                             $('#billing_dic').val(data.dic).trigger('change');
                        }
                        if (data.ic_dph && $('#billing_ic_dph').length) {
                             $('#billing_ic_dph').val(data.ic_dph).trigger('change');
                        }
                        
                        // Success visual (green border flash?)
                        icoField.css('border-color', '#46b450');
                        setTimeout(function(){ icoField.css('border-color', ''); }, 2000);
                        
                    } else {
                        // Error handling
                        console.log('BizAgent: ' + response.data.message);
                    }
                },
                error: function() {
                    icoField.prop('disabled', false);
                    container.removeClass('bizagent-loading');
                }
            });
        });
    }
});
