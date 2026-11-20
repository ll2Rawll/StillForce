'use strict'

const root = document.documentElement
const themeButton = document.getElementById('theme-button')
const themeColour = document.querySelector('meta[name="theme-color"]')

function showTheme(theme) {
  root.dataset.theme = theme
  const label = theme === 'dark' ? 'Use light theme' : 'Use dark theme'
  themeButton.setAttribute('aria-label', label)
  themeButton.title = label
  themeColour.content = theme === 'dark' ? '#090f20' : '#eef4fd'
}
showTheme(root.dataset.theme)
themeButton.addEventListener('click', () => {
  const next = root.dataset.theme === 'dark' ? 'light' : 'dark'
  showTheme(next)
  try { localStorage.setItem('stillforce-page-theme', next) } catch {}
})

const menuButton = document.getElementById('menu-button')
const nav = document.getElementById('navigation')
const compactHeader = matchMedia('(max-width: 47.99rem)')

function setMenu(open) {
  menuButton.setAttribute('aria-expanded', String(open))
  menuButton.setAttribute('aria-label', open ? 'Close navigation' : 'Open navigation')
  nav.dataset.open = String(open)
}
menuButton.addEventListener('click', () => setMenu(menuButton.getAttribute('aria-expanded') !== 'true'))
nav.addEventListener('click', event => {
  const link = event.target.closest('a')
  if (!link || nav.dataset.open !== 'true') return
  setMenu(false)
  const heading = document.querySelector(link.hash)?.querySelector('h2')
  if (heading) {
    heading.tabIndex = -1
    heading.focus({ preventScroll: true })
  }
})
document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && nav.dataset.open === 'true') {
    setMenu(false)
    menuButton.focus()
  }
})
document.addEventListener('pointerdown', event => {
  if (nav.dataset.open === 'true' && !event.target.closest('.masthead')) setMenu(false)
})
compactHeader.addEventListener('change', () => setMenu(false))

const cases = [...document.querySelectorAll('.game-case')]
const choices = [...document.querySelectorAll('[data-choice]')]
const coverName = document.getElementById('cover-name')

function featureCover(index) {
  const positions = ['front', 'left', 'right']
  cases.forEach((item, i) => {
    item.dataset.slot = positions[(i - index + cases.length) % cases.length]
    item.setAttribute('aria-pressed', String(i === index))
    choices[i].setAttribute('aria-pressed', String(i === index))
  })
  coverName.textContent = cases[index].querySelector('img').alt
}
cases.forEach((item, i) => {
  item.disabled = false
  item.addEventListener('click', () => featureCover(i))
})
choices.forEach((item, i) => item.addEventListener('click', () => featureCover(i)))

const galleryTabs = document.querySelector('.gallery-tabs')
const tabs = [...galleryTabs.querySelectorAll('[data-panel]')]
const panels = tabs.map(tab => document.getElementById('view-' + tab.dataset.panel))
galleryTabs.setAttribute('role', 'tablist')

function showPanel(selected, moveFocus) {
  tabs.forEach((tab, i) => {
    const active = i === selected
    tab.setAttribute('aria-selected', String(active))
    tab.tabIndex = active ? 0 : -1
    tab.classList.toggle('selected', active)
    panels[i].hidden = !active
  })
  if (moveFocus) tabs[selected].focus()
}
tabs.forEach((tab, i) => {
  const panel = panels[i]
  tab.id = 'tab-' + tab.dataset.panel
  tab.setAttribute('role', 'tab')
  tab.setAttribute('aria-controls', panel.id)
  panel.setAttribute('role', 'tabpanel')
  panel.setAttribute('aria-labelledby', tab.id)
  tab.addEventListener('click', event => {
    if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return
    event.preventDefault()
    showPanel(i, false)
  })
  tab.addEventListener('keydown', event => {
    let target = i
    switch (event.key) {
      case 'ArrowRight': target = (i + 1) % tabs.length; break
      case 'ArrowLeft': target = (i + tabs.length - 1) % tabs.length; break
      case 'Home': target = 0; break
      case 'End': target = tabs.length - 1; break
      case ' ': break
      default: return
    }
    event.preventDefault()
    showPanel(target, true)
  })
})
showPanel(0, false)

const film = document.getElementById('trailer-player')
const startFilm = document.getElementById('film-start')
film.controls = false
startFilm.addEventListener('click', async () => {
  film.controls = true
  startFilm.hidden = true
  film.focus({ preventScroll: true })
  try {
    await film.play()
  } catch {
    startFilm.hidden = false
  }
})
film.addEventListener('play', () => { startFilm.hidden = true })
film.addEventListener('ended', () => {
  startFilm.hidden = false
  startFilm.setAttribute('aria-label', 'Replay the Stillforce trailer')
})
