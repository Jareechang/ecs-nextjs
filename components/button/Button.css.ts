import { css, cx } from '@emotion/css'
import { lighten } from 'polished';

export const common = css`
  padding: 1em 2em;
`
export const error = cx(
  common,
  css`
    background: #f44336;
    &:hover {
      background: ${lighten(0.2, '#f44336')};
    }
  `
)

export const success = cx(
  common,
  css`
    background: lightgreen;
    &:hover {
      background: ${lighten(0.2, 'lightgreen')};
    }
  `
)
