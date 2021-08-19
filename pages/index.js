import Head from 'next/head'
import Link from 'next/link'
import { css, cx } from '@emotion/css'
import Box from '@material-ui/core/Box';
import Typography from '@material-ui/core/Typography';
import Layout, { siteTitle } from '../components/layout'
import * as utilStyles from '../styles/utils.css'
import { getSortedPostsData } from '../lib/posts'
import Date from '../components/date'
import { Button } from '../components/button';

export default function Home({ allPostsData }) {
  return (
    <Layout home>
      <Head>
        <title>{siteTitle}</title>
      </Head>
      <section className={utilStyles.headingMd}>
        <Typography variant="body1">[Your Self Introduction]</Typography>
        <Typography
          variant="body1">
          (This is a sample website - you’ll be building a site like this in{' '}
          <a href="https://nextjs.org/learn">our Next.js tutorial</a>.)
        </Typography>
      </section>
      <Box
        py={3}
        display="flex"
        justifyContent="center">
        <Button
          type="error"
          variant="contained"
          color="primary">
          I’m a button
        </Button>
      </Box>
      <section className={cx(utilStyles.headingMd, utilStyles.padding1px)}>
        <h2 className={utilStyles.headingLg}>Blog</h2>
        <ul className={utilStyles.list}>
          {allPostsData.map(({ id, date, title }) => (
            <li className={utilStyles.listItem} key={id}>
              <Link href={`/posts/${id}`}>
                <a>{title}</a>
              </Link>
              <br />
              <small className={utilStyles.lightText}>
                <Date dateString={date} />
              </small>
            </li>
          ))}
        </ul>
      </section>
    </Layout>
  )
}

export async function getStaticProps() {
  const allPostsData = getSortedPostsData()
  return {
    props: {
      allPostsData
    }
  }
}
