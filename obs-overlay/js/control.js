(() => {
  const frame = document.getElementById('overlay-preview');
  const preview = document.querySelector('.preview-frame');
  const matchLabelInput = document.getElementById('match-label-input');
  const layoutEditButton = document.getElementById('layout-edit-button');
  let layoutEdit = false;

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

  function setLayoutEdit(enabled) {
    layoutEdit = Boolean(enabled);
    send('SET_LAYOUT_EDIT', { enabled: layoutEdit });
    if (!layoutEditButton) return;
    layoutEditButton.textContent = layoutEdit ? 'Disable Layout Edit' : 'Enable Layout Edit';
    layoutEditButton.classList.toggle('active', layoutEdit);
  }

  document.addEventListener('click', (event) => {
    if (event.target.closest('#layout-edit-button')) {
      setLayoutEdit(!layoutEdit);
      return;
    }

    const button = event.target.closest('button[data-action]');
    if (!button) return;
    send(button.dataset.action, payloadFor(button));
    if (button.dataset.action === 'RESET') {
      if (matchLabelInput) matchLabelInput.value = 'M7';
      setLayoutEdit(false);
    }
  });

  matchLabelInput?.addEventListener('input', () => {
    send('SET_MATCH_LABEL', { value: matchLabelInput.value });
  });

  frame.addEventListener('load', () => {
    setLayoutEdit(layoutEdit);
  });

  window.addEventListener('resize', resizePreview);
  if ('ResizeObserver' in window) new ResizeObserver(resizePreview).observe(preview);
  resizePreview();

  window.MLETMControl = { send, setLayoutEdit };
})();
