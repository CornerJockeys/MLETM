(() => {
  const frame = document.getElementById('overlay-preview');
  const preview = document.querySelector('.preview-frame');

  function resizePreview() {
    const scale = preview.clientWidth / 1920;
    frame.style.transform = `scale(${scale})`;
  }

  function payloadFor(button) {
    const payload = {};
    if (button.dataset.widget) payload.widget = button.dataset.widget;
    if (button.dataset.side) payload.side = button.dataset.side;
    if (button.dataset.delta) payload.delta = Number(button.dataset.delta);
    if (button.dataset.index) payload.index = Number(button.dataset.index);
    return payload;
  }

  function send(action, payload = {}) {
    frame.contentWindow?.postMessage({ type: 'mletm-action', action, payload }, '*');
  }

  document.addEventListener('click', (event) => {
    const button = event.target.closest('button[data-action]');
    if (!button) return;
    send(button.dataset.action, payloadFor(button));
  });

  window.addEventListener('resize', resizePreview);
  if ('ResizeObserver' in window) new ResizeObserver(resizePreview).observe(preview);
  resizePreview();

  window.MLETMControl = { send };
})();
