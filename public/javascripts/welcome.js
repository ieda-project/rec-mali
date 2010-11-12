window.addEvent('domready', function() {
  $$('.welcome .choose button').addEvent('click', function() {
    $$('.welcome>div').setStyle('display', 'none');
    $$('.welcome>div.'+this.className).setStyle('display', 'block');
    $$('.welcome>div.back').setStyle('display', 'block');
  })
  $$('.welcome .back a').addEvent('click', function() {
    $$('.welcome>div').setStyle('display', 'none');
    $$('.welcome>div.choose').setStyle('display', 'block');
  })
})
