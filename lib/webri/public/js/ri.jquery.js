
function lookup(elem, key) {
  if ($(elem).hasClass('trigger')) {
    $(elem).attr('display', 'block');
    $('#main').load('ri/' + key);
  } else {
    $('#main').load('ri/' + key);
  };
};

function showBranch(trigger) {
  var objTrigger = $(trigger);
  var objBranch  = objTrigger.siblings('.branch');
  if(objBranch.css('display') == "block") {
    objBranch.css('display', "none");
  } else {
    objBranch.css('display', "block");
  }
};

function swapFolder(img) {
  objImg = document.getElementById(img);
  if(objImg.src.indexOf('closed.gif')>-1) {
    objImg.src = openImg.src;
  } else {
    objImg.src = closedImg.src;
  }
};

function getWindowHeight() {
  var windowHeight = 0;
  if (typeof(window.innerHeight) == 'number') {
    windowHeight = window.innerHeight;
  }
  else {
    if (document.documentElement && document.documentElement.clientHeight) {
      windowHeight = document.documentElement.clientHeight;
    }
    else {
      if (document.body && document.body.clientHeight) {
        windowHeight = document.body.clientHeight;
      }
    }
  }
  return windowHeight;
};

function resizePage() {
  var side = document.getElementById('side');
  var main = document.getElementById('main');
  var h = getWindowHeight();
  var nh = (h - 153) + 'px';
  side.style.height = nh;
  main.style.height = nh;
};
