import MuiButton from '@material-ui/core/Button'
import Props from './types'
import * as styles from './Button.css'
import * as utils from './utils'

const defaultProps : Props = {
  type: ''
}

const Button : React.FC<Props> = (props = defaultProps) => {
  return (
    <MuiButton
      className={utils.mapButtonTypeToStyle(props.type)}
      {...props}
    />
  )
}

export default Button
