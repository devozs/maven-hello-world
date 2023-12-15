package com.myapp;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

/**
 * Unit test for simple App.
 */
public class AppTest
{
    /**
     * Rigorous Test :-)
     */
    @Test
    public void shouldAnswerWithTrue()
    {
        assertTrue( true );
    }
    @Test
    public void testCreateMessageWithName() {
        String name = "Oz";
        String expected = "Hello World! Oz";
        String actual = App.createMessage(name);
        assertEquals(expected, actual);
    }

    @Test
    public void testCreateMessageWithAnonymous() {
        String expected = "Hello World! Anonymous";
        String actual = App.createMessage(null);
        assertEquals(expected, actual);
    }

}
