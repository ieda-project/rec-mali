window.addEvent('domready', function() {
  $$('.welcome .choose button').addEvent('click', function() {
    $$('.welcome>div').setStyle('display', 'none');
    $$('.welcome>div.'+this.className).setStyle('display', 'block');
    $$('.welcome>div.back').setStyle('display', 'block');
  });

  $$('.welcome .back a').addEvent('click', function() {
    $$('.welcome>div').setStyle('display', 'none');
    $$('.welcome>div.choose').setStyle('display', 'block');
  });

  $$('form').addEvent('submit', function(e) {
    var sel = this.getElement('select'),
        opt = sel.selectedOptions[0], ret = false;
    if (opt) ret = confirm(
      'Vous avez sélectionné ' +
      opt.get('text').trimLeft() +
      '. Etes-vous sûr ?');

    this.stop = !ret;
    return ret;
  });
})
