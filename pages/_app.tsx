import { CacheProvider } from '@emotion/react'
import { cache } from '@emotion/css'
import { ThemeProvider } from '@material-ui/core/styles';
import { StylesProvider } from '@material-ui/core/styles';

import theme from '../styles/material-ui/theme';

export default function App({ Component, pageProps }) {
  React.useEffect(() => {
    // Remove the server-side injected CSS.
    const jssStyles = document.querySelector('#jss-server-side');
    if (jssStyles) {
      jssStyles.parentElement.removeChild(jssStyles);
    }
  }, []);
  return (
    <StylesProvider injectFirst>
      <ThemeProvider theme={theme}>
        <CacheProvider value={cache}>
          <Component {...pageProps} />
        </CacheProvider>
      </ThemeProvider >
    </StylesProvider>
  );
}
