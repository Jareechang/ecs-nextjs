import * as styles from './Button.css'

export const mapButtonTypeToStyle = (type) => {
  switch (type) {
    case 'error':
      return styles.error;
    case 'success':
      return styles.success;
    default:
      return styles.common;
  }
}
